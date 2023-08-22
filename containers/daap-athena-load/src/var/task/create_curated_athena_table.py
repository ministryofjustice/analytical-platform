import os
import time

import boto3
from botocore.exceptions import ClientError
from create_raw_athena_table import create_glue_database
from data_platform_logging import DataPlatformLogger
from infer_glue_schema import infer_glue_schema

athena_client = boto3.client("athena")
s3_client = boto3.client("s3")
glue_client = boto3.client("glue")


def create_curated_athena_table(
    database_name: str,
    table_name: str,
    curated_path: str,
    bucket: str,
    extraction_timestamp: str,
    metadata,
    logger: DataPlatformLogger,
    s3_security_opts,
):
    """
    creates curated parquet file from raw file and updates table
    to include latest timestamp partition from raw file uploaded.
    Loads data as a string into the raw athena table, then casts
    it to it's inferred type in the curated table with a timestamp.
    """

    table_exists = False
    create_glue_database(glue_client, database_name, logger, bucket, s3_security_opts)

    try:
        table_metadata = glue_client.get_table(
            DatabaseName=database_name, Name=table_name
        )
        if "table_metadata" in locals():
            table_exists = True

    except ClientError as e:
        curated_prefix = curated_path.replace("s3://" + bucket + "/", "")
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
                    database_name,
                    table_name,
                    curated_path,
                    extraction_timestamp,
                    metadata,
                ),
                s3_security_opts=s3_security_opts,
                logger=logger,
            )
            logger.info(
                f"This is a new data product. Created {database_name}.{table_name}, using query id {qid}"
            )

            return

    partition_file_exists = does_partition_file_exist(
        bucket,
        database_name,
        table_name,
        extraction_timestamp,
        logger=logger,
    )

    if table_exists and not partition_file_exists:
        logger.info("table does already exist but partition for timestamp does not")
        # unload query to make partitioned data
        qid = start_query_execution_and_wait(
            "data_products_raw",
            bucket,
            sql_unload_table_partition(
                extraction_timestamp, table_name, curated_path, metadata
            ),
            s3_security_opts=s3_security_opts,
            logger=logger,
        )

        logger.info(
            "Updated table {0}.{1}, using query id {2}".format(
                database_name, table_name, qid
            )
        )
        refresh_table_partitions(database_name, table_name)

    elif not table_exists and partition_file_exists:
        logger.info("partition data exists but glue table does not")
        table_metadata, _ = infer_glue_schema(
            curated_path,
            database_name=database_name,
            file_type="parquet",
            table_type="curated",
            logger=logger,
        )

        glue_client.create_table(**table_metadata)
        refresh_table_partitions(database_name, table_name)
    elif not table_exists and not partition_file_exists:
        logger.info("table and partition do not exist but other curated data do")
        # unload query to make partitioned data
        qid = start_query_execution_and_wait(
            "data_products_raw",
            bucket,
            sql_unload_table_partition(
                extraction_timestamp, table_name, curated_path, metadata
            ),
            s3_security_opts=s3_security_opts,
            logger=logger,
        )
        logger.info(f"created files for partition using query id {qid}")
        table_metadata, _ = infer_glue_schema(
            curated_path,
            database_name=database_name,
            file_type="parquet",
            table_type="curated",
            logger=logger,
        )
        glue_client.create_table(**table_metadata)
        refresh_table_partitions(database_name, table_name)

    else:
        logger.info(
            "partition for extraction_timestamp and table already exists so nothing more to be done."
        )


def start_query_execution_and_wait(
    database_name: str,
    data_bucket: str,
    sql: str,
    s3_security_opts: dict,
    logger: DataPlatformLogger,
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
            logger.write_log_dict_to_s3_json(bucket=data_bucket, **s3_security_opts)
            raise ValueError(e)
        else:
            logger.error(f"unexpected error: {e}")
            logger.write_log_dict_to_s3_json(bucket=data_bucket, **s3_security_opts)
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
        logger.write_log_dict_to_s3_json(bucket=data_bucket, **s3_security_opts)
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
    timestamp: str, table_name: str, table_path: str, metadata: dict
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
            FROM data_products_raw.{table_name}_raw
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
    database_name: str, table_name: str, table_path: str, timestamp: str, metadata: dict
) -> str:
    """
    if the table and data do not exist in curated this
    will create initial table and parition in glue and file
    in s3
    """
    partition_sql = f"""
        CREATE TABLE {database_name}.{table_name}
        WITH(
            format='parquet',
            write_compression = 'SNAPPY',
            external_location='{table_path}',
            partitioned_by=ARRAY['extraction_timestamp']
        ) AS
        SELECT
            {_get_column_names_and_types(metadata)},
            '{timestamp}' as extraction_timestamp
        FROM data_products_raw.{table_name}_raw
    """

    return partition_sql


def refresh_table_partitions(database_name: str, table_name: str) -> None:
    """
    refreshes partitions following an update to a table
    """
    athena_client.start_query_execution(
        QueryString=f"MSCK REPAIR TABLE {database_name}.{table_name}",
        WorkGroup="data_product_workgroup",
    )


def does_partition_file_exist(
    bucket: str,
    db_name: str,
    table_name: str,
    timestamp: str,
    logger: DataPlatformLogger,
) -> bool:
    """
    returns bool indicating whether the extraction timestamp for
    a data product already exists
    """

    db_path = f"database_name={db_name}"
    table_path = f"table_name={table_name}/"
    paginator = s3_client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(
        Bucket=bucket, Prefix=os.path.join("curated_data", db_path, table_path)
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
