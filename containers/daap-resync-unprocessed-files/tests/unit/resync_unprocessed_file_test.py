import pytest
from resync_unprocessed_files import (
    get_data_product_pages,
    get_resync_keys,
    get_unique_load_timestamps,
)


@pytest.fixture
def empty_curated_data_bucket(s3_client):
    bucket_name = "curated"
    s3_client.create_bucket(Bucket=bucket_name)
    return bucket_name


@pytest.fixture
def empty_raw_data_bucket(s3_client):
    bucket_name = "raw"
    s3_client.create_bucket(Bucket=bucket_name)
    return bucket_name


@pytest.fixture
def raw_data_bucket(s3_client, empty_raw_data_bucket, data_element):
    bucket_name = empty_raw_data_bucket
    s3_client.put_object(
        Bucket=bucket_name,
        Key=data_element.raw_data_prefix.key + "load_timestamp=timestamp1/file1.csv",
        Body="Test data in file 1",
    )
    s3_client.put_object(
        Bucket=bucket_name,
        Key=data_element.raw_data_prefix.key + "load_timestamp=timestamp2/file2.csv",
        Body="Test data in file 2",
    )
    s3_client.put_object(
        Bucket=bucket_name,
        Key=data_element.raw_data_prefix.key + "load_timestamp=timestamp1/file3.csv",
        Body="Test data in same extraction time stamp but different file",
    )
    return bucket_name


@pytest.fixture
def curated_data_bucket(s3_client, empty_curated_data_bucket, data_element):
    bucket_name = empty_curated_data_bucket
    s3_client.put_object(
        Bucket=bucket_name,
        Key=f"{data_element.curated_data_prefix.key}load_timestamp=timestamp1"
        + "/file1.parquet",
        Body="This is test File",
    )
    s3_client.put_object(Bucket=bucket_name, Key="some-other", Body="One more file")
    return bucket_name


def test_get_raw_data_unique_extraction_timestamps(
    s3_client, raw_data_bucket, data_element
):
    pages = get_data_product_pages(
        bucket=raw_data_bucket,
        data_product_prefix=data_element.raw_data_prefix.key,
        s3_client=s3_client,
    )
    raw_table_timestamp = sorted(get_unique_load_timestamps(pages))
    assert {i for i in raw_table_timestamp} == {
        "data_product/v1/table_name/load_timestamp=timestamp1",
        "data_product/v1/table_name/load_timestamp=timestamp2",
    }


def test_get_curated_unique_extraction_timestamps(
    s3_client, curated_data_bucket, data_element
):
    pages = get_data_product_pages(
        bucket=curated_data_bucket,
        data_product_prefix=data_element.curated_data_prefix.key,
        s3_client=s3_client,
    )

    curated_table_timestamp = sorted(get_unique_load_timestamps(pages))
    assert {i for i in curated_table_timestamp} == {
        "data_product/v1/table_name/load_timestamp=timestamp1"
    }


def test_get_resync_keys(s3_client, data_element, raw_data_bucket, curated_data_bucket):
    raw_pages = get_data_product_pages(
        bucket=raw_data_bucket,
        data_product_prefix=data_element.raw_data_prefix.key,
        s3_client=s3_client,
    )
    raw_table_timestamps = sorted(get_unique_load_timestamps(raw_pages))

    curated_pages = get_data_product_pages(
        bucket=curated_data_bucket,
        data_product_prefix=data_element.curated_data_prefix.key,
        s3_client=s3_client,
    )

    curated_table_timestamps = sorted(get_unique_load_timestamps(curated_pages))

    raw_keys_to_resync = get_resync_keys(
        raw_table_timestamps, curated_table_timestamps, raw_pages
    )

    assert {i for i in raw_keys_to_resync} == {
        "raw/data_product/v1/table_name/" + "load_timestamp=timestamp2/file2.csv"
    }
