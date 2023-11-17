from textwrap import dedent

from curated_data.curated_data_query_builder import CuratedDataQueryBuilder, QueryTable


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
