from data_platform_logging import DataPlatformLogger
from data_platform_paths import DataProductElement, QueryTable
from data_product_metadata import DataProductSchema, format_table_schema
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
        load_timestamp: str,
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
                timestamp=load_timestamp,
                curated_table=self.curated_data_table,
                raw_table=raw_data_table,
            ),
            logger=self.logger,
        )
        self.logger.info(f"Created {self.curated_data_table}, using query id {qid}")

    def ingest_raw_data(self, raw_data_table: QueryTable, load_timestamp: str):
        """
        Ingest raw data into the curated tables. This creates new partition files in s3.
        """
        qid = start_query_execution_and_wait(
            database_name=self.curated_data_table.database,
            sql=self.query_builder.sql_unload_table_partition(
                timestamp=load_timestamp, raw_table=raw_data_table
            ),
            logger=self.logger,
        )
        self.logger.info(f"Updated {self.curated_data_table}, using query id {qid}")

        refresh_table_partitions(
            database_name=self.curated_data_table.database,
            table_name=self.curated_data_table.name,
        )

    def create_new_major_version_data_product_table(self, is_updated_table):
        """
        Creates new data product version tables

        As the updated table (cause of the verison increase) is already created
        it uses an UNLOAD rather than CTAS query
        """
        if not is_updated_table:
            qid = start_query_execution_and_wait(
                database_name=self.curated_data_table.database,
                sql=self.query_builder.sql_create_next_major_increment_table(
                    self.curated_data_table,
                ),
                logger=self.logger,
            )
            self.logger.info(f"created {self.curated_data_table}, using query id {qid}")
        else:
            qid = start_query_execution_and_wait(
                database_name=self.curated_data_table.database,
                sql=self.query_builder.sql_unload_for_major_updated_table(
                    curated_table=self.curated_data_table,
                ),
                logger=self.logger,
            )
            self.logger.info(
                f"unloaded {self.curated_data_table}, using query id {qid}"
            )
            refresh_table_partitions(
                database_name=self.curated_data_table.database,
                table_name=self.curated_data_table.name,
            )


class CuratedDataCopier:
    def __init__(
        self,
        element: DataProductElement,
        athena_client,
        glue_client,
        new_schema: DataProductSchema,
        logger=DataPlatformLogger,
        schemas_to_copy=None,
        column_changes=None,
        schema_delete: bool = False,
    ):
        """
        Copy data from existing version of data product to new version of
        data product.
        """
        self.schema = new_schema if new_schema else None
        self.data_product_name = element.data_product.name
        self.column_changes = column_changes
        self.new_curated_data_product_path = element.curated_data_prefix.uri
        self.new_database_name = element.database_name
        self.schemas_to_copy = schemas_to_copy
        self.glue_client = glue_client
        self.athena_client = athena_client
        self.logger = logger
        self.schema_delete = schema_delete
        self._get_tables_to_copy()

    def _is_updated_table_valid_for_copy(self):
        """
        Check whether it is possible to copy the data of changed schema
        between two major versions

        Columns removed -> OK (will be ignored by athena)
        Columns added -> OK (will be left as null)
        Columns reordered -> OK
        Data types changed -> Not OK
        """

        if self.column_changes is not None and self.column_changes["types_changed"]:
            return False
        else:
            return True

    def run(self) -> list[DataProductSchema]:
        """
        This runs the actual copy of each data product table into the new database version

        The table for where schema has been updated is created via boto3
        as it will not always have data loaded to it via this method

        returns a list of updated DataProductSchema objects to caller
        """
        # create new version database and table for updated schema
        if self.column_changes is not None:
            create_glue_database(self.glue_client, self.new_database_name, self.logger)
            parquet_table_input = format_parquet_glue_table_input(
                self.schema.data["TableInput"],
                self.new_curated_data_product_path,
            )
            self.glue_client.create_table(
                DatabaseName=self.new_database_name,
                TableInput=parquet_table_input,
            )
        schemas_for_rewrite = []
        for table in self.tables_to_copy:
            input_data = format_table_schema(
                (
                    DataProductSchema(
                        data_product_name=self.data_product_name,
                        table_name=table,
                        logger=self.logger,
                        input_data=None,
                    )
                    .load()
                    .latest_version_saved_data
                )
            )
            schema_for_copy = DataProductSchema(
                data_product_name=self.data_product_name,
                table_name=table,
                logger=self.logger,
                input_data=input_data,
            )
            schema_for_copy.convert_schema_to_glue_table_input_csv()
            CuratedDataLoader(
                column_metadata=schema_for_copy.data["TableInput"]["StorageDescriptor"][
                    "Columns"
                ],
                table=QueryTable(
                    database=schema_for_copy.database_name,
                    name=schema_for_copy.table_name,
                ),
                table_path=self.new_curated_data_product_path.replace(
                    self.schema.table_name, table
                ),
                athena_client=self.athena_client,
                glue_client=self.glue_client,
                logger=self.logger,
            ).create_new_major_version_data_product_table(
                is_updated_table=(table == self.schema.table_name)
            )
            schemas_for_rewrite.append(schema_for_copy)

        return schemas_for_rewrite

    def _get_tables_to_copy(self):
        """
        Creates a list of tables to copy into new version of data product database
        """
        if self.schemas_to_copy:
            self.tables_to_copy = self.schemas_to_copy
        elif self._is_updated_table_valid_for_copy():
            self.tables_to_copy = self.schema.parent_data_product_metadata["schemas"]
            self.copy_updated_table = True
        else:
            self.tables_to_copy = [
                table
                for table in self.schema.parent_data_product_metadata["schemas"]
                if not table == self.schema.table_name
            ]
            self.copy_updated_table = False

        return self


def format_parquet_glue_table_input(schema: dict, location: str) -> dict:
    """
    populate the saved schema glue table input with parameters to make partitioned
    parquet curated table
    """
    schema["StorageDescriptor"][
        "InputFormat"
    ] = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    schema["StorageDescriptor"][
        "OutputFormat"
    ] = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    schema["StorageDescriptor"]["Location"] = location
    schema["StorageDescriptor"]["SerdeInfo"] = {
        "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe",
        "Parameters": {"serialization.format": "1"},
    }
    schema["StorageDescriptor"]["Parameters"] = {
        "classification": "parquet",
        "compressionType": "SNAPPY",
    }
    schema["PartitionKeys"] = [{"Name": "load_timestamp", "Type": "varchar(16)"}]
    schema["Parameters"] = {"classification": "parquet"}

    return schema
