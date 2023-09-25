from textwrap import dedent

import pytest
from create_curated_athena_table import (
    CuratedDataLoader,
    CuratedDataQueryBuilder,
    TableMissingForExistingDataProduct,
    create_curated_athena_table,
    does_partition_file_exist,
)
from data_platform_paths import BucketPath, QueryTable


class TestCreateCuratedAthenaTable:
    @pytest.fixture(autouse=True)
    def setup(self, s3_client, athena_client):
        s3_client.create_bucket(Bucket="bucket")
        athena_client.create_work_group(Name="data_product_workgroup")

    @pytest.fixture
    def function_kwargs(
        self, data_product_element, s3_client, glue_client, athena_client, logger
    ):
        """
        Helper to construct the args to the function
        """
        return dict(
            data_product_element=data_product_element,
            raw_data_table=data_product_element.raw_data_table_unique(),
            extraction_timestamp="20230101T000000Z",
            metadata={
                "TableInput": {"Name": "table", "StorageDescriptor": {"Columns": []}},
                "DatabaseName": "data_products_raw",
            },
            logger=logger,
            glue_client=glue_client,
            s3_client=s3_client,
            athena_client=athena_client,
        )

    def test_creates_glue_database_for_new_product(
        self, data_product_element, function_kwargs, glue_client, caplog
    ):
        create_curated_athena_table(**function_kwargs)
        response = glue_client.get_database(
            Name=data_product_element.curated_data_table.database
        )

        assert response["ResponseMetadata"]["HTTPStatusCode"] == 200
        assert "This is a new data product" in caplog.text

    def test_no_error_if_table_exists(
        self, function_kwargs, data_product_element, glue_client, caplog
    ):
        glue_client.create_database(
            DatabaseInput={"Name": data_product_element.curated_data_table.database}
        )
        glue_client.create_table(
            TableInput={"Name": data_product_element.curated_data_table.name},
            DatabaseName=data_product_element.curated_data_table.database,
        )

        create_curated_athena_table(**function_kwargs)

        assert "Table exists but partition does not" in caplog.text

    def test_no_error_if_table_and_partition_exist(
        self,
        function_kwargs,
        s3_client,
        glue_client,
        data_product_element,
        caplog,
    ):
        glue_client.create_database(
            DatabaseInput={"Name": data_product_element.curated_data_table.database}
        )
        glue_client.create_table(
            TableInput={"Name": data_product_element.curated_data_table.name},
            DatabaseName=data_product_element.curated_data_table.database,
        )
        s3_client.put_object(
            Bucket="bucket",
            Key=data_product_element.curated_data_prefix.key
            + "extraction_timestamp=20230101T000000Z/partition.parquet",
            Body="",
        )

        create_curated_athena_table(**function_kwargs)

        assert (
            "partition for extraction_timestamp and table already exists so nothing more to be done."
            in caplog.text
        )

    def test_errors_if_table_is_missing_and_path_non_empty(
        self,
        data_product_element,
        s3_client,
        function_kwargs,
    ):
        s3_client.put_object(
            Bucket="bucket",
            Key=data_product_element.curated_data_prefix.key + "partition.parquet",
            Body="",
        )

        with pytest.raises(TableMissingForExistingDataProduct):
            create_curated_athena_table(**function_kwargs)


class TestCuratedDataQueryBuilder:
    def test_sql_unload_table_partition(self):
        builder = CuratedDataQueryBuilder(
            table_path="s3://bucket_name/curated_data/database_name=dataproduct/table_name=table_name/",
            column_metadata=[
                {"Name": "foo", "Type": "string"},
                {"Name": "bar", "Type": None},
            ],
        )
        result = builder.sql_unload_table_partition(
            raw_table=QueryTable("data_products_raw", "table_raw"),
            timestamp="20230101T000000Z",
        )

        assert dedent(result) == dedent(
            """
            UNLOAD (
                SELECT
                    CAST(NULLIF("foo",'') as VARCHAR) as "foo",CAST(NULLIF("bar",'') as None) as "bar",
                    '20230101T000000Z' as extraction_timestamp
                FROM data_products_raw.table_raw
            )
            TO 's3://bucket_name/curated_data/database_name=dataproduct/table_name=table_name/'
            WITH(
                format='parquet',
                compression = 'SNAPPY',
                partitioned_by=ARRAY['extraction_timestamp']
            )
            """
        )

    def test_sql_create_table_partition(self):
        builder = CuratedDataQueryBuilder(
            table_path="s3://bucket_name/curated_data/database_name=dataproduct/table_name=table_name/",
            column_metadata=[
                {"Name": "foo", "Type": "string"},
                {"Name": "bar", "Type": None},
            ],
        )

        result = builder.sql_create_table_partition(
            raw_table=QueryTable("data_products_raw", "table_raw"),
            curated_table=QueryTable("db", "table"),
            timestamp="20230101T000000Z",
        )

        assert dedent(result) == dedent(
            """
            CREATE TABLE db.table
            WITH(
                format='parquet',
                write_compression = 'SNAPPY',
                external_location='s3://bucket_name/curated_data/database_name=dataproduct/table_name=table_name/',
                partitioned_by=ARRAY['extraction_timestamp']
            ) AS
            SELECT
                CAST(NULLIF("foo",'') as VARCHAR) as "foo",CAST(NULLIF("bar",'') as None) as "bar",
                '20230101T000000Z' as extraction_timestamp
            FROM data_products_raw.table_raw
            """
        )


class TestDoesPartitionFileExist:
    def test_returns_true(self, s3_client, logger):
        s3_client.create_bucket(Bucket="bucket")
        s3_client.put_object(
            Key="curated_data/db/table_name/foo.parquet", Body="", Bucket="bucket"
        )

        assert not does_partition_file_exist(
            curated_data_prefix=BucketPath(
                "bucket", "curated_data/database=db/table=table_name/"
            ),
            timestamp="20230101T0000Z",
            logger=logger,
            s3_client=s3_client,
        )

    def test_returns_false(self, s3_client, logger):
        s3_client.create_bucket(Bucket="bucket")

        assert not does_partition_file_exist(
            curated_data_prefix=BucketPath(
                "bucket", "curated_data/database=db/table=table_name/"
            ),
            timestamp="20230101T0000Z",
            logger=logger,
            s3_client=s3_client,
        )


class TestCuratedDataLoader:
    @pytest.fixture(autouse=True)
    def setup(self, athena_client):
        athena_client.create_work_group(Name="data_product_workgroup")

    @pytest.fixture
    def loader(self, logger, data_product_element, athena_client, glue_client):
        return CuratedDataLoader(
            column_metadata=[
                {"Name": "foo", "Type": "string"},
                {"Name": "bar", "Type": "string"},
            ],
            table=data_product_element.curated_data_table,
            table_path="s3://foo",
            athena_client=athena_client,
            glue_client=glue_client,
            logger=logger,
        )

    def test_create_for_new_data_product_executes_athena_query(
        self,
        loader,
        athena_client,
    ):
        loader.create_for_new_data_product(
            raw_data_table=QueryTable("data_products_raw", "table"),
            extraction_timestamp="20000101T000000Z",
        )

        assert len(athena_client.list_query_executions()["QueryExecutionIds"]) == 1

    def test_ingest_raw_data_executes_athena_query(
        self,
        loader,
        athena_client,
    ):
        loader.ingest_raw_data(
            raw_data_table=QueryTable("data_products_raw", "table"),
            extraction_timestamp="20000101T000000Z",
        )

        assert len(athena_client.list_query_executions()["QueryExecutionIds"]) == 2
