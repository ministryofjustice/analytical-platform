import re
import uuid
from datetime import datetime
import pytest

from data_platform_paths import (
    DATABASE_NAME_REGEX,
    EXTRACTION_TIMESTAMP_CURATED_REGEX,
    TABLE_NAME_REGEX,
    BucketPath,
    DataProductConfig,
    DataProductElement,
    RawDataExtraction,
    data_product_log_bucket_and_key,
    get_curated_data_bucket,
    get_landing_zone_bucket,
    get_log_bucket,
    get_metadata_bucket,
    get_raw_data_bucket,
    search_string_for_regex
)
from freezegun import freeze_time

curated_data_key = [
    "curated_data/database_name=data_product/table_name=table/"
    + "extraction_timestamp=timestamp/file.parquet"
]


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


def test_raw_data_bucket(monkeypatch):
    monkeypatch.setenv("RAW_DATA_BUCKET", "a-bucket")
    assert get_raw_data_bucket() == "a-bucket"


def test_curated_data_bucket(monkeypatch):
    monkeypatch.setenv("CURATED_DATA_BUCKET", "a-bucket")
    assert get_curated_data_bucket() == "a-bucket"


def test_landing_zone_bucket(monkeypatch):
    monkeypatch.setenv("LANDING_ZONE_BUCKET", "a-bucket")
    assert get_landing_zone_bucket() == "a-bucket"


def test_log_bucket(monkeypatch):
    monkeypatch.setenv("LOG_BUCKET", "a-bucket")
    assert get_log_bucket() == "a-bucket"


def test_metdata_bucket(monkeypatch):
    monkeypatch.setenv("METADATA_BUCKET", "a-bucket")
    assert get_metadata_bucket() == "a-bucket"


def test_raw_data_bucket_defaults_to_old_environment_variable(monkeypatch):
    monkeypatch.setenv("BUCKET_NAME", "a-bucket")
    assert get_raw_data_bucket() == "a-bucket"


def test_data_product_config_metadata_spec_prefix():
    assert DataProductConfig.metadata_spec_prefix("bucket") == BucketPath(
        bucket="bucket", key="data_product_metadata_spec"
    )


def test_data_product_element_config(monkeypatch):
    monkeypatch.setenv("RAW_DATA_BUCKET", "bucket")
    monkeypatch.setenv("CURATED_DATA_BUCKET", "bucket")
    monkeypatch.setenv("METADATA_BUCKET", "bucket")
    monkeypatch.setenv("LANDING_ZONE_BUCKET", "bucket")

    element = DataProductElement.load("some-table", "data-product")

    raw_data_table = element.raw_data_table_unique()

    assert re.match(
        r"some-table_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}_raw",
        raw_data_table.name,
    )
    assert raw_data_table.database == "data_products_raw"
    assert element.curated_data_table.name == "some-table"
    assert element.curated_data_table.database == "data-product"

    assert element.raw_data_prefix == BucketPath(
        bucket="bucket",
        key="raw_data/data-product/some-table/",
    )

    assert element.curated_data_prefix == BucketPath(
        bucket="bucket",
        key="curated_data/database_name=data-product/table_name=some-table/",
    )


def test_data_product_config_path_prefixes():
    config = DataProductConfig(
        name="my-database",
        raw_data_bucket="raw-bucket",
        curated_data_bucket="curated-bucket",
        metadata_bucket="a-bucket",
        landing_zone_bucket="a-bucket",
    )

    assert config.raw_data_prefix == BucketPath(
        bucket="raw-bucket", key="raw_data/my-database/"
    )
    assert config.curated_data_prefix == BucketPath(
        bucket="curated-bucket", key="curated_data/database_name=my-database/"
    )


def test_data_product_config_get_element():
    config = DataProductConfig(
        name="my-database",
        raw_data_bucket="a-bucket",
        curated_data_bucket="a-bucket",
        metadata_bucket="a-bucket",
        landing_zone_bucket="a-bucket",
    )

    element = config.element("some-table")
    assert element.name == "some-table"


def test_data_product_element_raw_data_path():
    uuid_value = uuid.uuid4()
    timestamp = datetime(2023, 9, 5, 16, 53)

    config = DataProductConfig(
        name="my-database",
        raw_data_bucket="a-bucket",
        curated_data_bucket="a-bucket",
        metadata_bucket="a-bucket",
        landing_zone_bucket="a-bucket",
    )
    element = config.element("some-table")

    path = element.raw_data_path(timestamp=timestamp, uuid_value=uuid_value)

    assert path == BucketPath(
        bucket="a-bucket",
        key=f"raw_data/my-database/some-table/extraction_timestamp=20230905T165300Z/{uuid_value}",
    )


def test_data_product_config_metadata_path():
    config = DataProductConfig(
        name="my-database",
        curated_data_bucket="a-bucket",
        raw_data_bucket="a-bucket",
        landing_zone_bucket="a-bucket",
        metadata_bucket="a-bucket",
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
        raw_data_bucket="a-bucket",
        curated_data_bucket="a-bucket",
        landing_zone_bucket="a-bucket",
        metadata_bucket="a-bucket",
    )

    element = config.element("some-table")

    extraction = element.extraction_instance(uuid_value=uuid_value, timestamp=timestamp)

    assert extraction.timestamp == timestamp
    assert extraction.path == BucketPath(
        bucket="a-bucket",
        key=f"raw_data/my-database/some-table/extraction_timestamp=20230905T165300Z/{uuid_value}",
    )


def test_extraction_config_parse_from_raw_uri(monkeypatch):
    monkeypatch.setenv("CURATED_DATA_BUCKET", "bucket2")
    monkeypatch.setenv("METADATA_BUCKET", "bucket3")
    monkeypatch.setenv("LANDING_ZONE_BUCKET", "bucket4")

    raw_data_uri = (
        "s3://bucket1/raw_data/database-name/table-name/extraction_timestamp=20230905T162700Z/"
        + "7cf8e644-06af-47ce-8f5f-b53c22a35f2e"
    )

    config = RawDataExtraction.parse_from_uri(raw_data_uri)

    assert config.path == BucketPath(
        bucket="bucket1",
        key=(
            "raw_data/database-name/table-name/extraction_timestamp=20230905T162700Z/"
            + "7cf8e644-06af-47ce-8f5f-b53c22a35f2e"
        ),
    )
    assert config.timestamp == datetime(2023, 9, 5, 16, 27)
    assert config.element.data_product == DataProductConfig(
        name="database-name",
        raw_data_bucket="bucket1",
        curated_data_bucket="bucket2",
        metadata_bucket="bucket3",
        landing_zone_bucket="bucket4",
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
    assert (
        log_bucket_path.key
        == "logs/json/lambda_name=top_test_lambda/data_product_name=delicious-data-product/date=2023-09-12/2023-09-12T00:00:00:000_log.json"  # noqa: E501
    )


@pytest.mark.parametrize("curated_data_key", curated_data_key)
def test_extract_table_name_from_curated_path(curated_data_key):
    assert search_string_for_regex(curated_data_key, TABLE_NAME_REGEX) == "table"


@pytest.mark.parametrize("curated_data_key", curated_data_key)
def test_extract_database_name_from_curated_path(curated_data_key):
    assert (
        search_string_for_regex(curated_data_key, regex=DATABASE_NAME_REGEX)
        == "data_product"
    )


@pytest.mark.parametrize("curated_data_key", curated_data_key)
def test_extract_timestamp_from_curated_path(curated_data_key):
    assert (
        search_string_for_regex(
            curated_data_key, regex=EXTRACTION_TIMESTAMP_CURATED_REGEX
        )
        == "timestamp"
    )
