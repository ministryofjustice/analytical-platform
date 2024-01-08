from textwrap import dedent

from curated_data.curated_data_query_builder import CuratedDataQueryBuilder, QueryTable


class TestCuratedDataQueryBuilder:
    def test_sql_unload_table_partition(self):
        builder = CuratedDataQueryBuilder(
            table_path="s3://bucket_name/curated_data/database_name=dataproduct/table_name=table_name/",
            column_metadata=[
                {"Name": "foo", "Type": "string"},
                {"Name": "bar", "Type": None},
                {"Name": "value", "Type": "float"},
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
                    CAST(NULLIF({col_name},0) as real) as "value",'20230101T000000Z' as load_timestamp
                FROM data_products_raw.table_raw
            )
            TO 's3://bucket_name/curated_data/database_name=dataproduct/table_name=table_name/'
            WITH(
                format='parquet',
                compression = 'SNAPPY',
                partitioned_by=ARRAY['load_timestamp']
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
                partitioned_by=ARRAY['load_timestamp']
            ) AS
            SELECT
                CAST(NULLIF("foo",'') as VARCHAR) as "foo",CAST(NULLIF("bar",'') as None) as "bar",
                '20230101T000000Z' as load_timestamp
            FROM data_products_raw.table_raw
            """
        )

    def test_sql_create_next_major_increment_table(self):
        builder = CuratedDataQueryBuilder(
            table_path="s3://bucket_name/curated/v2/database_name=dataproduct/table_name=table_name/",
            column_metadata=[
                {"Name": "foo", "Type": "string"},
                {"Name": "bar", "Type": None},
            ],
        )
        result = builder.sql_create_next_major_increment_table(
            new_curated_table=QueryTable("dataproduct_v2", "table_name"),
        )

        assert dedent(result) == dedent(
            """
                CREATE TABLE dataproduct_v2.table_name
                WITH(
                    format='parquet',
                    write_compression = 'SNAPPY',
                    external_location='s3://bucket_name/curated/v2/database_name=dataproduct/table_name=table_name/',
                    partitioned_by=ARRAY['load_timestamp']
                ) AS
                SELECT
                    *
                FROM dataproduct_v1.table_name
                WHERE load_timestamp = (
                    SELECT MAX(load_timestamp)
                    FROM dataproduct_v1.table_name
                )
            """
        )

    def test_sql_unload_for_major_updated_table(self):
        builder = CuratedDataQueryBuilder(
            table_path="s3://bucket_name/curated/v2/database_name=dataproduct/table_name=table_name/",
            column_metadata=[
                {"Name": "foo", "Type": "string"},
                {"Name": "bar", "Type": None},
            ],
        )
        result = builder.sql_unload_for_major_updated_table(
            curated_table=QueryTable("dataproduct_v2", "table_name"),
        )

        assert dedent(result) == dedent(
            """
                UNLOAD (
                    SELECT
                        *
                    FROM dataproduct_v1.table_name
                    WHERE load_timestamp = (
                        SELECT MAX(load_timestamp)
                        FROM dataproduct_v1.table_name
                    )
                )
                TO 's3://bucket_name/curated/v2/database_name=dataproduct/table_name=table_name/'
                WITH(
                    format='parquet',
                    compression = 'SNAPPY',
                    partitioned_by=ARRAY['load_timestamp']
                )
            """
        )
