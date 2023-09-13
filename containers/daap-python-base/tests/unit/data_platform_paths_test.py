import uuid
from datetime import datetime

from data_platform_paths import (
    BucketPath,
    DataProductConfig,
    ExtractionConfig,
    QueryTable,
    data_product_curated_data_prefix,
    data_product_log_bucket_and_key,
    data_product_metadata_file_path,
    data_product_raw_data_file_path,
    get_bucket_name,
)
from freezegun import freeze_time


def test_bucket_path_can_be_reassembled():
    uri = "s3://bucket/path/to/something"
    path = BucketPath.from_uri(uri)
    new_path = BucketPath(bucket=path.bucket, key=path.key)

    assert path == new_path
    assert path.uri == new_path.uri


def test_bucket_path_bucket_and_key():
    uri = "s3://bucket/path/to/something"
    path = BucketPath.from_uri(uri)

    assert path.bucket == "bucket"
    assert path.key == "path/to/something"


def test_bucket_path_parent():
    uri = "s3://bucket/path/to/something"
    path = BucketPath.from_uri(uri)

    assert path.parent.key == "path/to"


def test_bucket_name_returns_environment_variable(monkeypatch):
    monkeypatch.setenv("BUCKET_NAME", "a-bucket")
    assert get_bucket_name() == "a-bucket"


def test_data_product_metadata_file_path(monkeypatch):
    monkeypatch.setenv("BUCKET_NAME", "a-bucket")
    metadata_path = data_product_metadata_file_path("delicious-data-product")

    assert (
        metadata_path
        == "s3://a-bucket/metadata/delicious-data-product/v1.0/metadata.json"
    )


def test_data_product_raw_data_file_path():
    uuid_value = uuid.uuid4()
    timestamp = datetime(2023, 9, 6)
    path = data_product_raw_data_file_path(
        data_product_name="data-product",
        table_name="table",
        bucket_name="bucket",
        extraction_timestamp=timestamp,
        uuid_value=uuid_value,
    )

    assert (
        path
        == f"s3://bucket/raw_data/data-product/table/extraction_timestamp=20230906T000000Z/{uuid_value}"
    )


def test_get_data_product_curated_data_prefix():
    uri = data_product_curated_data_prefix(
        data_product_name="foo", table_name="table", bucket_name="bucket"
    )
    assert uri == "s3://bucket/curated_data/database_name=foo/table_name=table/"


def test_data_product_config():
    config = DataProductConfig(
        name="my-database",
        table_name="some-table",
        bucket_name="a-bucket",
    )

    assert config.raw_data_table.name == "some-table_raw"
    assert config.raw_data_table.database == "data_products_raw"
    assert config.curated_data_table.name == "some-table"
    assert config.curated_data_table.database == "my-database"

    assert config.raw_data_prefix == BucketPath(
        bucket="a-bucket",
        key="raw_data/my-database/some-table/",
    )

    assert config.curated_data_prefix == BucketPath(
        bucket="a-bucket",
        key="curated_data/database_name=my-database/table_name=some-table/",
    )


def test_data_product_config_raw_data_path():
    uuid_value = uuid.uuid4()
    timestamp = datetime(2023, 9, 5, 16, 53)

    config = DataProductConfig(
        name="my-database",
        table_name="some-table",
        bucket_name="a-bucket",
    )

    path = config.raw_data_path(timestamp=timestamp, uuid_value=uuid_value)

    assert path == BucketPath(
        bucket="a-bucket",
        key=f"raw_data/my-database/some-table/extraction_timestamp=20230905T165300Z/{uuid_value}",
    )


def test_data_product_config_metadata_path():
    config = DataProductConfig(
        name="my-database",
        table_name="some-table",
        bucket_name="a-bucket",
    )

    path = config.metadata_path()

    assert path == BucketPath(
        bucket="a-bucket",
        key="metadata/my-database/v1.0/metadata.json",
    )


def test_extraction_config():
    uuid_value = uuid.uuid4()
    timestamp = datetime(2023, 9, 5, 16, 53)

    config = DataProductConfig(
        name="my-database",
        table_name="some-table",
        bucket_name="a-bucket",
    )

    extraction = config.extraction_config(uuid_value=uuid_value, timestamp=timestamp)

    assert extraction.timestamp == timestamp
    assert extraction.path == BucketPath(
        bucket="a-bucket",
        key=f"raw_data/my-database/some-table/extraction_timestamp=20230905T165300Z/{uuid_value}",
    )


def test_extraction_config_parse_from_raw_uri():
    raw_data_uri = (
        "s3://a-bucket/raw_data/database-name/table-name/extraction_timestamp=20230905T162700Z/"
        + "7cf8e644-06af-47ce-8f5f-b53c22a35f2e"
    )

    config = ExtractionConfig.parse_from_uri(raw_data_uri)

    assert config.path == BucketPath(
        bucket="a-bucket",
        key=(
            "raw_data/database-name/table-name/extraction_timestamp=20230905T162700Z/"
            + "7cf8e644-06af-47ce-8f5f-b53c22a35f2e"
        ),
    )
    assert config.timestamp == datetime(2023, 9, 5, 16, 27)

    assert config.data_product_config.name == "database-name"
    assert config.data_product_config.curated_data_table == QueryTable(
        "database-name", "table-name"
    )
    assert config.data_product_config.raw_data_table == QueryTable(
        "data_products_raw", "table-name_raw"
    )
    assert config.data_product_config.raw_data_prefix == BucketPath(
        "a-bucket", "raw_data/database-name/table-name/"
    )
    assert config.data_product_config.curated_data_prefix == BucketPath(
        "a-bucket", "curated_data/database_name=database-name/table_name=table-name/"
    )


def test_data_product_metadata_spec_path():
    version = "1"
    path = DataProductConfig.metadata_spec_path(version, bucket_name="foo")

    assert path == BucketPath(
        bucket="foo",
        key="data_product_metadata_spec/1/moj_data_product_metadata_spec.json",
    )


@freeze_time("2023-09-12")
def test_data_product_log_bucket_and_key(monkeypatch):
    monkeypatch.setenv("BUCKET_NAME", "a-bucket")
    log_bucket_path = data_product_log_bucket_and_key(
        "top_test_lambda", "delicious-data-product"
    )

    assert log_bucket_path.bucket == "a-bucket"
    assert log_bucket_path.key == "logs/json/lambda_name=top_test_lambda/data_product_name=delicious-data-product/date=2023-09-12/2023-09-12T00:00:00:000_log.json"  # noqa: E501
