from textwrap import dedent
from unittest.mock import MagicMock

import pytest
from create_curated_athena_table import (
    create_curated_athena_table,
    does_partition_file_exist,
    sql_create_table_partition,
    sql_unload_table_partition,
)
from data_platform_logging import DataPlatformLogger
from data_platform_paths import BucketPath, QueryTable


@pytest.fixture
def curated_athena_table_kwargs(
    data_product, s3_client, glue_client, athena_client, logger
):
    """
    Helper to construct the args to the function
    """
    return dict(
        data_product_config=data_product,
        extraction_timestamp="20230101T000000Z",
        metadata={
            "TableInput": {"Name": "table", "StorageDescriptor": {"Columns": []}},
            "DatabaseName": "data_products_raw",
        },
        logger=logger,
        s3_security_opts={
            "ACL": "bucket-owner-full-control",
            "ServerSideEncryption": "AES256",
        },
        glue_client=glue_client,
        s3_client=s3_client,
        athena_client=athena_client,
    )


def test_creates_glue_database_if_missing(
    data_product, curated_athena_table_kwargs, s3_client, glue_client, athena_client
):
    s3_client.create_bucket(Bucket="bucket")
    athena_client.create_work_group(Name="data_product_workgroup")

    create_curated_athena_table(**curated_athena_table_kwargs)

    response = glue_client.get_database(Name=data_product.curated_data_table.database)
    assert response["ResponseMetadata"]["HTTPStatusCode"] == 200


def test_no_error_if_table_exists(
    curated_athena_table_kwargs, data_product, s3_client, glue_client, athena_client
):
    s3_client.create_bucket(Bucket="bucket")
    athena_client.create_work_group(Name="data_product_workgroup")
    glue_client.create_database(
        DatabaseInput={"Name": data_product.curated_data_table.database}
    )
    glue_client.create_table(
        TableInput={"Name": data_product.curated_data_table.name},
        DatabaseName=data_product.curated_data_table.database,
    )

    create_curated_athena_table(**curated_athena_table_kwargs)

    response = glue_client.get_database(Name=data_product.curated_data_table.database)
    assert response["ResponseMetadata"]["HTTPStatusCode"] == 200


def test_no_error_if_table_exists_and_partition_exists(
    curated_athena_table_kwargs,
    s3_client,
    glue_client,
    athena_client,
    data_product,
):
    s3_client.create_bucket(Bucket="bucket")
    s3_client.put_object(
        Bucket="bucket",
        Key=data_product.curated_data_prefix.key + "partition.parquet",
        Body="",
    )
    athena_client.create_work_group(Name="data_product_workgroup")
    glue_client.create_database(
        DatabaseInput={"Name": data_product.curated_data_table.database}
    )
    glue_client.create_table(
        TableInput={"Name": data_product.curated_data_table.name},
        DatabaseName=data_product.curated_data_table.database,
    )

    create_curated_athena_table(**curated_athena_table_kwargs)

    response = glue_client.get_database(Name=data_product.curated_data_table.database)
    assert response["ResponseMetadata"]["HTTPStatusCode"] == 200


def test_sql_unload_table_partition():
    result = sql_unload_table_partition(
        raw_table=QueryTable("data_products_raw", "table_raw"),
        table_path="s3://bucket_name/curated_data/database_name=dataproduct/table_name=table_name/",
        timestamp="20230101T000000Z",
        metadata={
            "TableInput": {
                "StorageDescriptor": {
                    "Columns": [
                        {"Name": "foo", "Type": "string"},
                        {"Name": "bar", "Type": None},
                    ]
                }
            }
        },
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


def test_sql_create_table_partition():
    result = sql_create_table_partition(
        raw_table=QueryTable("data_products_raw", "table_raw"),
        curated_table=QueryTable("db", "table"),
        table_path="s3://bucket_name/curated_data/database_name=dataproduct/table_name=table_name/",
        timestamp="20230101T000000Z",
        metadata={
            "TableInput": {
                "StorageDescriptor": {
                    "Columns": [
                        {"Name": "foo", "Type": "string"},
                        {"Name": "bar", "Type": None},
                    ]
                }
            }
        },
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


def test_does_partition_file_exist_returns_false(s3_client):
    logger = MagicMock(DataPlatformLogger)

    s3_client.create_bucket(Bucket="bucket")

    assert not does_partition_file_exist(
        curated_data_prefix=BucketPath(
            "bucket", "curated_data/database=db/table=table_name/"
        ),
        timestamp="20230101T0000Z",
        logger=logger,
        s3_client=s3_client,
    )


def test_does_partition_file_exist_returns_true(s3_client):
    logger = MagicMock(DataPlatformLogger)

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
