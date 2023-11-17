import time

from botocore.exceptions import ClientError
from data_platform_logging import DataPlatformLogger
from data_platform_paths import QueryTable
from glue_utils import create_glue_database

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
