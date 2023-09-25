import time

from botocore.exceptions import ClientError
from create_raw_athena_table import create_glue_database
from data_platform_logging import DataPlatformLogger
from data_platform_paths import BucketPath, QueryTable


class TableMissingForExistingDataProduct(Exception):
    pass


class CuratedDataQueryBuilder:
    """
    Builds queries for processing raw data, via athena.
    """

    def __init__(self, column_metadata: list[dict[str, str]], table_path: str):
        """
        Args:
            column_metadata - glue metadata for the columns in the table
            table_path - path to the partition files in the curated data bucket
        """
        self.table_path: str
        self.column_metadata = column_metadata
        self.table_path = table_path

    def _get_column_names_and_types(self) -> str:
        select_list = []
        for column in self.column_metadata:
            col_name = '"' + column["Name"] + '"'
            col_type = column["Type"] if not column["Type"] == "string" else "VARCHAR"
            col_no_zero_len_str = f"NULLIF({col_name},'')"
            select_list.append(
                f"CAST({col_no_zero_len_str} as {col_type}) as {col_name}"
            )

        select_str = ",".join(select_list)

        return select_str

    def sql_unload_table_partition(self, timestamp: str, raw_table: QueryTable) -> str:
        """
        generates sql string to unload a timestamped partition
        of raw data to given s3 location
        """
        partition_sql = f"""
            UNLOAD (
                SELECT
                    {self._get_column_names_and_types()},
                    '{timestamp}' as extraction_timestamp
                FROM {raw_table.database}.{raw_table.name}
            )
            TO '{self.table_path}'
            WITH(
                format='parquet',
                compression = 'SNAPPY',
                partitioned_by=ARRAY['extraction_timestamp']
            )
        """

        return partition_sql

    def sql_create_table_partition(
        self, raw_table: QueryTable, curated_table: QueryTable, timestamp: str
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
                external_location='{self.table_path}',
                partitioned_by=ARRAY['extraction_timestamp']
            ) AS
            SELECT
                {self._get_column_names_and_types()},
                '{timestamp}' as extraction_timestamp
            FROM {raw_table.database}.{raw_table.name}
        """

        return partition_sql


class CuratedDataLoader:
    """
    Helper class to ingest data into the curated data bucket via athena.
    """

    def __init__(
        self,
        column_metadata: list[dict[str, str]],
        table_path: str,
        table: QueryTable,
        athena_client,
        glue_client,
        logger: DataPlatformLogger,
    ):
        """
        Args:
            column_metadata - glue metadata for the columns
            table_path - path to the partition files in the curated data bucket
            table - tuple of database name and table name for the curated athena table
        """
        self.athena_client = athena_client
        self.glue_client = glue_client
        self.column_metadata = column_metadata
        self.logger = logger
        self.query_builder = CuratedDataQueryBuilder(
            column_metadata=column_metadata, table_path=table_path
        )
        self.curated_table_path = table_path
        self.curated_data_table = table

    def create_for_new_data_product(
        self,
        raw_data_table: QueryTable,
        extraction_timestamp: str,
    ):
        """
        Create the partitions using athena for a new data product;
        i.e. there are no partition files already
        """
        create_glue_database(
            self.glue_client, self.curated_data_table.database, self.logger
        )
        qid = self._start_query_execution_and_wait(
            self.curated_data_table.database,
            self.query_builder.sql_create_table_partition(
                timestamp=extraction_timestamp,
                curated_table=self.curated_data_table,
                raw_table=raw_data_table,
            ),
        )
        self.logger.info(f"Created {self.curated_data_table}, using query id {qid}")

    def ingest_raw_data(self, raw_data_table: QueryTable, extraction_timestamp: str):
        """
        Ingest raw data into the curated tables. This creates new partition files in s3.
        """
        qid = self._start_query_execution_and_wait(
            raw_data_table.database,
            self.query_builder.sql_unload_table_partition(
                timestamp=extraction_timestamp, raw_table=raw_data_table
            ),
        )

        self.logger.info(f"Updated {self.curated_data_table}, using query id {qid}")
        self.refresh_table_partitions()

    def refresh_table_partitions(self) -> None:
        """
        Refreshes partitions following an update to a table
        """
        self.athena_client.start_query_execution(
            QueryString=f"MSCK REPAIR TABLE {self.curated_data_table.database}.{self.curated_data_table.name}",
            WorkGroup="data_product_workgroup",
        )

    def table_exists(self) -> bool:
        """
        Check if the curated data table exists in the glue catalog
        """
        try:
            self.glue_client.get_table(
                DatabaseName=self.curated_data_table.database,
                Name=self.curated_data_table.name,
            )
        except ClientError as e:
            if e.response["Error"]["Code"] == "EntityNotFoundException":
                return False
            else:
                raise
        return True

    def _start_query_execution_and_wait(
        self,
        database_name: str,
        sql: str,
    ) -> str:
        """
        runs query for given sql and waits for completion
        """
        try:
            res = self.athena_client.start_query_execution(
                QueryString=sql,
                QueryExecutionContext={"Database": database_name},
                WorkGroup="data_product_workgroup",
            )
        except ClientError as e:
            if e.response["Error"]["Code"] == "InvalidRequestException":
                self.logger.error(f"This sql caused an error: {sql}")
                raise ValueError(e)
            else:
                self.logger.error(f"unexpected error: {e}")
                raise ValueError(e)

        query_id = res["QueryExecutionId"]
        while response := self.athena_client.get_query_execution(
            QueryExecutionId=query_id
        ):
            state = response["QueryExecution"]["Status"]["State"]
            if state not in ["SUCCEEDED", "FAILED"]:
                time.sleep(0.1)
            else:
                break

        if not state == "SUCCEEDED":
            self.logger.error(
                "Query_id {}, failed with response: {}".format(
                    query_id,
                    response["QueryExecution"]["Status"].get("StateChangeReason"),
                )
            )
            raise ValueError(
                response["QueryExecution"]["Status"].get("StateChangeReason")
            )

        return query_id


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
    loader = CuratedDataLoader(
        column_metadata=metadata["TableInput"]["StorageDescriptor"]["Columns"],
        table_path=data_product_element.curated_data_prefix.uri,
        table=data_product_element.curated_data_table,
        athena_client=athena_client,
        glue_client=glue_client,
        logger=logger,
    )

    table_exists = loader.table_exists()

    partition_file_exists = does_partition_file_exist(
        data_product_element.curated_data_prefix,
        extraction_timestamp,
        logger=logger,
        s3_client=s3_client,
    )

    if table_exists and partition_file_exists:
        logger.info(
            "partition for extraction_timestamp and table already exists so nothing more to be done."
        )
        return

    if table_exists:
        logger.info("Table exists but partition does not")
        loader.ingest_raw_data(
            raw_data_table=raw_data_table, extraction_timestamp=extraction_timestamp
        )
        return

    if (
        s3_client.list_objects_v2(
            Bucket=data_product_element.curated_data_prefix.bucket,
            Prefix=data_product_element.curated_data_prefix.key,
        )["KeyCount"]
        == 0
    ):
        logger.info("This is a new data product.")
        loader.create_for_new_data_product(
            raw_data_table=raw_data_table, extraction_timestamp=extraction_timestamp
        )
        return

    logger.info(
        f"{loader.curated_data_table} does not exist,"
        f" but files exist in {loader.curated_table_path}."
        " Run reload_data_product to recreate the data product before continuing."
    )
    raise TableMissingForExistingDataProduct()


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
