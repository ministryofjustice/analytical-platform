import pytest
from resync_unprocessed_files import (
    get_data_product_pages,
    get_raw_data_unique_extraction_timestamps,
)

# get_data_product_pages - There is test associated in different containers
#  get_raw_data_unique_extraction_timestamps - need a test for it


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
def raw_data_bucket(s3_client, empty_raw_data_bucket, data_product):
    bucket_name = empty_raw_data_bucket
    s3_client.put_object(
        Bucket=bucket_name,
        Key=data_product.raw_data_prefix.key
        + "extraction_timestamp=timestamp1/file1.csv",
        Body="Test data in file 1",
    )
    s3_client.put_object(
        Bucket=bucket_name,
        Key=data_product.raw_data_prefix.key
        + "extraction_timestamp=timestamp2/file2.csv",
        Body="Test data in file 2",
    )
    s3_client.put_object(
        Bucket=bucket_name,
        Key=data_product.raw_data_prefix.key
        + "extraction_timestamp=timestamp1/file3.csv",
        Body="Test data in same extraction time stamp but different file",
    )
    return bucket_name


def test_get_raw_data_unique_extraction_timestamps(
    s3_client, raw_data_bucket, data_product
):

    pages = get_data_product_pages(
            bucket=raw_data_bucket,
            page_size=1,
            data_product_prefix=data_product.raw_data_prefix.key,
            s3_client=s3_client,
        )
    raw_table_timestamp = get_raw_data_unique_extraction_timestamps(pages)
    assert {i for i in raw_table_timestamp} == {
        "data_product/table_name/extraction_timestamp=timestamp1",
        "data_product/table_name/extraction_timestamp=timestamp2",
    }
