from data_platform_logging import DataPlatformLogger
from data_platform_paths import QueryTable
from glue_and_athena_utils import (
    create_glue_database,
    refresh_table_partitions,
    start_query_execution_and_wait,
)

from .curated_data_query_builder import CuratedDataQueryBuilder


class CuratedDataLoader:
    """
    Ingest data into the curated data bucket via athena.
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

        qid = start_query_execution_and_wait(
            database_name=self.curated_data_table.database,
            sql=self.query_builder.sql_create_table_partition(
                timestamp=extraction_timestamp,
                curated_table=self.curated_data_table,
                raw_table=raw_data_table,
            ),
            logger=self.logger,
        )
        self.logger.info(f"Created {self.curated_data_table}, using query id {qid}")

    def ingest_raw_data(self, raw_data_table: QueryTable, extraction_timestamp: str):
        """
        Ingest raw data into the curated tables. This creates new partition files in s3.
        """
        qid = start_query_execution_and_wait(
            database_name=self.curated_data_table.database,
            sql=self.query_builder.sql_unload_table_partition(
                timestamp=extraction_timestamp, raw_table=raw_data_table
            ),
            logger=self.logger,
        )
        self.logger.info(f"Updated {self.curated_data_table}, using query id {qid}")

        refresh_table_partitions(
            database_name=self.curated_data_table.database,
            table_name=self.curated_data_table.name,
        )
