import time

from botocore.exceptions import ClientError
from create_raw_athena_table import create_glue_database
from data_platform_logging import DataPlatformLogger
from data_platform_paths import BucketPath, QueryTable
from infer_glue_schema import infer_glue_schema


def create_curated_athena_table(
    data_product_element,
    raw_data_table: QueryTable,
    extraction_timestamp,
    metadata,
    logger: DataPlatformLogger,
    athena_client,
    s3_client,
    glue_client,
):
    """
    creates curated parquet file from raw file and updates table
    to include latest timestamp partition from raw file uploaded.
    Loads data as a string into the raw athena table, then casts
    it to it's inferred type in the curated table with a timestamp.
    """
    database_name = data_product_element.curated_data_table.database
    table_name = data_product_element.curated_data_table.name
    curated_path = data_product_element.curated_data_prefix.uri
    bucket = data_product_element.raw_data_prefix.bucket

    table_exists = False
    create_glue_database(glue_client, database_name, logger, bucket)

    try:
        table_metadata = glue_client.get_table(
            DatabaseName=database_name, Name=table_name
        )
        if "table_metadata" in locals():
            table_exists = True

    except ClientError as e:
        curated_prefix = data_product_element.curated_data_prefix.key
        existing_files = s3_client.list_objects_v2(
            Bucket=bucket, Prefix=curated_prefix
        )["KeyCount"]
        if (
            e.response["Error"]["Code"] == "EntityNotFoundException"
            and existing_files == 0
        ):
            # only want to run this query if no table or data exist in s3
            qid = start_query_execution_and_wait(
                database_name,
                bucket,
                sql_create_table_partition(
                    data_product_element.curated_data_table,
                    raw_data_table,
                    curated_path,
                    extraction_timestamp,
                    metadata,
                ),
                logger=logger,
                athena_client=athena_client,
            )
            logger.info(
                f"This is a new data product. Created {database_name}.{table_name}, using query id {qid}"
            )

            return

    partition_file_exists = does_partition_file_exist(
        data_product_element.curated_data_prefix,
        extraction_timestamp,
        logger=logger,
        s3_client=s3_client,
    )

    if table_exists and not partition_file_exists:
        logger.info("table does already exist but partition for timestamp does not")
        # unload query to make partitioned data
        qid = start_query_execution_and_wait(
            raw_data_table.database,
            bucket,
            sql_unload_table_partition(
                extraction_timestamp,
                raw_data_table,
                curated_path,
                metadata,
            ),
            logger=logger,
            athena_client=athena_client,
        )

        logger.info(
            "Updated table {0}.{1}, using query id {2}".format(
                database_name, table_name, qid
            )
        )
        refresh_table_partitions(database_name, table_name, athena_client=athena_client)

    elif not table_exists and partition_file_exists:
        logger.info("partition data exists but glue table does not")
        table_metadata, _ = infer_glue_schema(
            data_product_element.curated_data_prefix,
            data_product_element,
            file_type="parquet",
            table_type="curated",
            logger=logger,
        )

        glue_client.create_table(**table_metadata)
        refresh_table_partitions(database_name, table_name, athena_client=athena_client)
    elif not table_exists and not partition_file_exists:
        logger.info("table and partition do not exist but other curated data do")
        # unload query to make partitioned data
        qid = start_query_execution_and_wait(
            raw_data_table.database,
            bucket,
            sql_unload_table_partition(
                extraction_timestamp,
                raw_data_table,
                curated_path,
                metadata,
            ),
            logger=logger,
            athena_client=athena_client,
        )
        logger.info(f"created files for partition using query id {qid}")
        table_metadata, _ = infer_glue_schema(
            data_product_element.curated_data_prefix,
            data_product_element,
            file_type="parquet",
            table_type="curated",
            logger=logger,
        )
        glue_client.create_table(**table_metadata)
        refresh_table_partitions(database_name, table_name, athena_client=athena_client)

    else:
        logger.info(
            "partition for extraction_timestamp and table already exists so nothing more to be done."
        )


def start_query_execution_and_wait(
    database_name: str,
    data_bucket: str,
    sql: str,
    logger: DataPlatformLogger,
    athena_client,
) -> str:
    """
    runs query for given sql and waits for completion
    """
    try:
        res = athena_client.start_query_execution(
            QueryString=sql,
            QueryExecutionContext={"Database": database_name},
            WorkGroup="data_product_workgroup",
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "InvalidRequestException":
            logger.error(f"This sql caused an error: {sql}")
            raise ValueError(e)
        else:
            logger.error(f"unexpected error: {e}")
            raise ValueError(e)

    query_id = res["QueryExecutionId"]
    while response := athena_client.get_query_execution(QueryExecutionId=query_id):
        state = response["QueryExecution"]["Status"]["State"]
        if state not in ["SUCCEEDED", "FAILED"]:
            time.sleep(0.1)
        else:
            break

    if not state == "SUCCEEDED":
        logger.error(
            "Query_id {}, failed with response: {}".format(
                query_id, response["QueryExecution"]["Status"].get("StateChangeReason")
            )
        )
        raise ValueError(response["QueryExecution"]["Status"].get("StateChangeReason"))

    return query_id


def _get_column_names_and_types(metadata) -> str:
    select_list = []
    for column in metadata["TableInput"]["StorageDescriptor"]["Columns"]:
        col_name = '"' + column["Name"] + '"'
        col_type = column["Type"] if not column["Type"] == "string" else "VARCHAR"
        col_no_zero_len_str = f"NULLIF({col_name},'')"
        select_list.append(f"CAST({col_no_zero_len_str} as {col_type}) as {col_name}")

    select_str = ",".join(select_list)

    return select_str


def sql_unload_table_partition(
    timestamp: str, raw_table: QueryTable, table_path: str, metadata: dict
) -> str:
    """
    generates sql string to unload a timestamped partition
    of raw data to given s3 location
    """
    partition_sql = f"""
        UNLOAD (
            SELECT
                {_get_column_names_and_types(metadata)},
                '{timestamp}' as extraction_timestamp
            FROM {raw_table.database}.{raw_table.name}
        )
        TO '{table_path}'
        WITH(
            format='parquet',
            compression = 'SNAPPY',
            partitioned_by=ARRAY['extraction_timestamp']
        )
    """

    return partition_sql


def sql_create_table_partition(
    curated_table: QueryTable,
    raw_table: QueryTable,
    table_path: str,
    timestamp: str,
    metadata: dict,
) -> str:
    """
    if the table and data do not exist in curated this
    will create initial table and parition in glue and file
    in s3
    """
    partition_sql = f"""
        CREATE TABLE {curated_table.database}.{curated_table.name}
        WITH(
            format='parquet',
            write_compression = 'SNAPPY',
            external_location='{table_path}',
            partitioned_by=ARRAY['extraction_timestamp']
        ) AS
        SELECT
            {_get_column_names_and_types(metadata)},
            '{timestamp}' as extraction_timestamp
        FROM {raw_table.database}.{raw_table.name}
    """

    return partition_sql


def refresh_table_partitions(
    database_name: str, table_name: str, athena_client
) -> None:
    """
    refreshes partitions following an update to a table
    """
    athena_client.start_query_execution(
        QueryString=f"MSCK REPAIR TABLE {database_name}.{table_name}",
        WorkGroup="data_product_workgroup",
    )


def does_partition_file_exist(
    curated_data_prefix: BucketPath,
    timestamp: str,
    logger: DataPlatformLogger,
    s3_client,
) -> bool:
    """
    returns bool indicating whether the extraction timestamp for
    a data product already exists
    """

    paginator = s3_client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(
        Bucket=curated_data_prefix.bucket, Prefix=curated_data_prefix.key
    )
    response = []
    try:
        for page in page_iterator:
            response += page["Contents"]
    except KeyError as e:
        logger.error(
            f"No {e} key found at data product curated path – the database"
            " doesn't exist and will be created"
        )

    ts_exists = any(f"extraction_timestamp={timestamp}" in i["Key"] for i in response)
    logger.info(f"extraction_timestamp={timestamp} exists = {ts_exists}")

    return ts_exists
