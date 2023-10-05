import re
import uuid
from datetime import datetime
from unittest.mock import patch

import pytest
from data_platform_paths import (
    DATABASE_NAME_REGEX,
    LOAD_TIMESTAMP_CURATED_REGEX,
    TABLE_NAME_REGEX,
    BucketPath,
    DataProductConfig,
    DataProductElement,
    JsonSchemaName,
    RawDataExtraction,
    data_product_log_bucket_and_key,
    get_curated_data_bucket,
    get_landing_zone_bucket,
    get_latest_version,
    get_log_bucket,
    get_metadata_bucket,
    get_raw_data_bucket,
    search_string_for_regex,
    specification_path,
    specification_prefix,
)
from freezegun import freeze_time

curated_data_key = [
    "curated_data/database_name=data_product/table_name=table/"
    + "load_timestamp=timestamp/file.parquet"
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


def test_raw_data_bucket():
    assert get_raw_data_bucket() == "raw"


def test_curated_data_bucket():
    assert get_curated_data_bucket() == "curated"


def test_landing_zone_bucket():
    assert get_landing_zone_bucket() == "landing"


def test_log_bucket():
    assert get_log_bucket() == "logs"


def test_metadata_bucket():
    assert get_metadata_bucket() == "metadata"


def test_raw_data_bucket_defaults_to_old_environment_variable(monkeypatch):
    assert get_raw_data_bucket() == "raw"


def test_data_product_config_specification_prefix():
    assert specification_prefix(JsonSchemaName("metadata"), "bucket") == BucketPath(
        bucket="bucket", key="data_product_metadata_spec"
    )


def test_data_product_element_config(monkeypatch):
    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        element = DataProductElement.load("some_table", "data_product")

        raw_data_table = element.raw_data_table_unique()

        assert re.match(
            r"some_table_[0-9a-f]{8}_[0-9a-f]{4}_[0-9a-f]{4}_[0-9a-f]{4}_[0-9a-f]{12}_raw",
            raw_data_table.name,
        )
        assert raw_data_table.database == "data_products_raw"
        assert element.curated_data_table.name == "some_table"
        assert element.curated_data_table.database == "data_product"

        assert element.raw_data_prefix == BucketPath(
            bucket="raw",
            key="raw/data_product/v1.0/some_table/",
        )

        assert element.curated_data_prefix == BucketPath(
            bucket="curated",
            key="curated/data_product/v1.0/some_table/",
        )


def test_data_product_config_path_prefixes():
    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        config = DataProductConfig(
            name="my-database",
            raw_data_bucket="raw",
            curated_data_bucket="curated",
            metadata_bucket="metadata",
            landing_zone_bucket="landing",
        )

        assert config.raw_data_prefix == BucketPath(
            bucket="raw", key="raw/my-database/v1.0/"
        )
        assert config.curated_data_prefix == BucketPath(
            bucket="curated", key="curated/my-database/v1.0/"
        )

        assert config.landing_data_prefix == BucketPath(
            bucket="landing", key="landing/my-database/v1.0/"
        )


def test_data_product_config_get_element():
    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        config = DataProductConfig(
            name="my-database",
            raw_data_bucket="raw",
            curated_data_bucket="curated",
            metadata_bucket="metadata",
            landing_zone_bucket="landing",
        )

        element = config.element("some-table")
        assert element.name == "some-table"


def test_data_product_element_raw_data_path():
    uuid_value = uuid.uuid4()
    timestamp = datetime(2023, 9, 5, 16, 53)

    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        config = DataProductConfig(
            name="my-database",
            raw_data_bucket="raw",
            curated_data_bucket="curated",
            metadata_bucket="metadata",
            landing_zone_bucket="landing",
        )
        element = config.element("some-table")

        path = element.raw_data_path(timestamp=timestamp, uuid_value=uuid_value)

        assert path == BucketPath(
            bucket="raw",
            key=f"raw/my-database/v1.0/some-table/load_timestamp=20230905T165300Z/{uuid_value}",
        )


def test_data_product_config_metadata_path():
    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        config = DataProductConfig(
            name="my-database",
            curated_data_bucket="curated",
            raw_data_bucket="raw",
            landing_zone_bucket="landing",
            metadata_bucket="metadata",
        )

        path = config.metadata_path()

        assert path == BucketPath(
            bucket="metadata",
            key="my-database/v1.0/metadata.json",
        )


def test_extraction_config():
    uuid_value = uuid.uuid4()
    timestamp = datetime(2023, 9, 5, 16, 53)

    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        config = DataProductConfig(
            name="my-database",
            raw_data_bucket="raw",
            curated_data_bucket="curated",
            landing_zone_bucket="landing",
            metadata_bucket="metadata",
        )

        element = config.element("some-table")

        extraction = element.extraction_instance(
            uuid_value=uuid_value, timestamp=timestamp
        )

        assert extraction.timestamp == timestamp
        assert extraction.path == BucketPath(
            bucket="raw",
            key=f"raw/my-database/v1.0/some-table/load_timestamp=20230905T165300Z/{uuid_value}",
        )


def test_extraction_config_parse_from_raw_uri(monkeypatch):
    monkeypatch.setenv("CURATED_DATA_BUCKET", "bucket2")
    monkeypatch.setenv("METADATA_BUCKET", "bucket3")
    monkeypatch.setenv("LANDING_ZONE_BUCKET", "bucket4")

    raw_data_uri = (
        "s3://bucket1/raw/database-name/v1.0/table-name/load_timestamp=20230905T162700Z/"
        + "7cf8e644-06af-47ce-8f5f-b53c22a35f2e"
    )

    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        config = RawDataExtraction.parse_from_uri(raw_data_uri)

        assert config.path == BucketPath(
            bucket="bucket1",
            key=(
                "raw/database-name/v1.0/table-name/load_timestamp=20230905T162700Z/"
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


def test_data_product_specification_path():
    version = "1"
    path = specification_path(JsonSchemaName("metadata"), version, bucket_name="foo")

    assert path == BucketPath(
        bucket="foo",
        key="data_product_metadata_spec/1/moj_data_product_metadata_spec.json",
    )


@freeze_time("2023-09-12")
def test_data_product_log_bucket_and_key(monkeypatch):
    log_bucket_path = data_product_log_bucket_and_key(
        "top_test_lambda", "delicious-data-product"
    )

    assert log_bucket_path.bucket == "logs"
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
        search_string_for_regex(curated_data_key, regex=LOAD_TIMESTAMP_CURATED_REGEX)
        == "timestamp"
    )


def test_get_latest_version(region_name, s3_client, monkeypatch):
    with patch("data_platform_paths.s3", s3_client):
        s3_client.create_bucket(
            Bucket="metadata",
            CreateBucketConfiguration={"LocationConstraint": region_name},
        )
        # Old version
        s3_client.put_object(
            Bucket="metadata", Key="data_product/v1.0/metadata.json", Body="hi"
        )
        s3_client.put_object(
            Bucket="metadata", Key="data_product/v2.0/metadata.json", Body="hi"
        )
        s3_client.put_object(
            Bucket="metadata", Key="data_product/v2.1/metadata.json", Body="hi"
        )
        # This file is empty and so should be ignored
        s3_client.put_object(
            Bucket="metadata", Key="data_product/v5.1/metadata.json", Body=""
        )
        latest_version = get_latest_version("data_product")
        assert latest_version == "v2.1"
