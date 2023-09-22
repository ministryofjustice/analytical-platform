import time

from botocore.exceptions import ClientError
from create_raw_athena_table import create_glue_database
from data_platform_logging import DataPlatformLogger
from data_platform_paths import BucketPath, QueryTable, DataProductElement
from infer_glue_schema import GlueSchemaGenerator
import os
import s3fs
from pyarrow import parquet as pq


def get_first_parquet_file(
    curated_data_prefix: BucketPath, s3_client
) -> pq.ParquetDataset:
    """
    Return a ParquetDataset from a specific file within the curated data prefix.
    """
    curated_bucket, curated_prefix = curated_data_prefix
    key = s3_client.list_objects_v2(Bucket=curated_bucket, Prefix=curated_prefix)[
        "Contents"
    ][0]["Key"]
    file_path = os.path.join("s3://", curated_bucket, key)

    s3 = s3fs.S3FileSystem()

    return pq.ParquetDataset(file_path, filesystem=s3, use_legacy_dataset=False)


def get_table_metadata(glue_client, table_name: str, database_name: str) -> dict | None:
    """
    Return the table metadata, or None if it doesn't exist
    """
    try:
        return glue_client.get_table(DatabaseName=database_name, Name=table_name)

    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            return None

        raise


def any_existing_files(s3_client, bucket: str, curated_prefix: str):
    return bool(
        s3_client.list_objects_v2(Bucket=bucket, Prefix=curated_prefix)["KeyCount"]
    )


class CuratedDataLoader:
    def __init__(
        self,
        logger: DataPlatformLogger,
        athena_client,
        glue_client,
        data_product_element: DataProductElement,
    ):
        self.logger = logger
        self.athena_client = athena_client
        self.glue_client = glue_client
        self.schema_generator = GlueSchemaGenerator(logger)
        self.data_product_element = data_product_element

    def create_new_table(
        self,
        raw_data_table: QueryTable,
        extraction_timestamp: str,
        metadata: dict,
    ):
        """
        Create a new table for a brand new data product
        """
        database_name, table_name = self.data_product_element.curated_data_table
        curated_path = self.data_product_element.curated_data_prefix.uri

        qid = start_query_execution_and_wait(
            database_name,
            sql_create_table_partition(
                self.data_product_element.curated_data_table,
                raw_data_table,
                curated_path,
                extraction_timestamp,
                metadata,
            ),
            logger=self.logger,
            athena_client=self.athena_client,
        )
        self.logger.info(f"Created {database_name}.{table_name}, using query id {qid}")

    def unload_new_data(
        self,
        raw_data_table: QueryTable,
        extraction_timestamp: str,
        metadata: dict,
    ):
        """
        Unload new data for the given extraction_timestamp.
        """
        database_name, table_name = self.data_product_element.curated_data_table
        curated_path = self.data_product_element.curated_data_prefix.uri

        # unload query to make partitioned data
        qid = start_query_execution_and_wait(
            raw_data_table.database,
            sql_unload_table_partition(
                extraction_timestamp,
                raw_data_table,
                curated_path,
                metadata,
            ),
            logger=self.logger,
            athena_client=self.athena_client,
        )

        self.logger.info(
            "Updated table {0}.{1}, using query id {2}".format(
                database_name, table_name, qid
            )
        )
        refresh_table_partitions(
            database_name, table_name, athena_client=self.athena_client
        )

    def unload_new_data_and_create_table(
        self,
        raw_data_table: QueryTable,
        extraction_timestamp: str,
        metadata: dict,
    ):
        """
        Unload data for the given extraction_timestamp, and recreate
        missing glue metadata for the table.
        """
        database_name, table_name = self.data_product_element.curated_data_table
        curated_path = self.data_product_element.curated_data_prefix.uri

        # unload query to make partitioned data
        qid = start_query_execution_and_wait(
            raw_data_table.database,
            sql_unload_table_partition(
                extraction_timestamp,
                raw_data_table,
                curated_path,
                metadata,
            ),
            logger=self.logger,
            athena_client=self.athena_client,
        )
        self.logger.info(f"created files for partition using query id {qid}")

        arrow_table = get_first_parquet_file(
            curated_data_prefix=self.data_product_element.curated_data_prefix,
            s3_client=self.s3_client,
        )

        table_metadata, _ = self.schema_generator.generate_from_parquet_schema(
            arrow_table=arrow_table,
            table_name=self.data_product_element.curated_data_table.name,
            database_name=self.data_product_element.curated_data_table.database,
            table_location=self.data_product_element.curated_data_prefix.uri,
        )

        self.glue_client.create_table(**table_metadata)
        refresh_table_partitions(
            database_name, table_name, athena_client=self.athena_client
        )

    def recreate_table(
        self,
        data_product_element: DataProductElement,
    ):
        """
        Recreate the table in glue, given that the partitions already exist.
        """
        arrow_table = get_first_parquet_file(
            curated_data_prefix=data_product_element.curated_data_prefix,
            s3_client=self.s3_client,
        )

        database_name, table_name = data_product_element.curated_data_table

        table_metadata, _ = self.schema_generator.generate_from_parquet_schema(
            arrow_table=arrow_table,
            table_name=table_name,
            database_name=database_name,
            table_location=data_product_element.curated_data_prefix.uri,
        )

        self.glue_client.create_table(**table_metadata)
        refresh_table_partitions(
            database_name, table_name, athena_client=self.athena_client
        )


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
    database_name, table_name = data_product_element.curated_data_table

    create_glue_database(glue_client, database_name, logger)

    table_metadata = get_table_metadata(
        glue_client=glue_client, database_name=database_name, table_name=table_name
    )

    partition_file_exists = does_partition_file_exist(
        data_product_element.curated_data_prefix,
        extraction_timestamp,
        logger=logger,
        s3_client=s3_client,
    )

    any_files_exist = any_existing_files(
        s3_client=s3_client,
        bucket=data_product_element.curated_data_prefix.bucket,
        curated_prefix=data_product_element.curated_data_prefix.key,
    )

    curated_data_loader = CuratedDataLoader(
        logger=logger,
        athena_client=athena_client,
        glue_client=glue_client,
        data_product_element=data_product_element,
    )

    if table_metadata and partition_file_exists:
        logger.info(
            "partition for extraction_timestamp and table already exists so nothing more to be done."
        )
    elif table_metadata:
        logger.info("table does already exist but partition for timestamp does not")

        curated_data_loader.unload_new_data(
            raw_data_table=raw_data_table,
            extraction_timestamp=extraction_timestamp,
            metadata=metadata,
        )
    elif partition_file_exists:
        logger.info("partition data exists but glue table does not")
        curated_data_loader.recreate_table()
    elif any_files_exist:
        logger.info("table and partition do not exist but other curated data do")

        curated_data_loader.unload_new_data_and_recreate_table(
            raw_data_table=raw_data_table,
            extraction_timestamp=extraction_timestamp,
            metadata=metadata,
        )
    else:
        logger.info("This is a new data product.")

        curated_data_loader.create_new_table(
            raw_data_table=raw_data_table,
            extraction_timestamp=extraction_timestamp,
            metadata=metadata,
        )


def start_query_execution_and_wait(
    database_name: str,
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
