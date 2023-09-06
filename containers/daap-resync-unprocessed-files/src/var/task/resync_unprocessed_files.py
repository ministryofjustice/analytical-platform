import os
import re

import boto3
from botocore.paginate import PageIterator
from data_platform_logging import DataPlatformLogger

s3 = boto3.client("s3")
logger = DataPlatformLogger(
    extra={
        "image_version": os.getenv("VERSION", "unknown"),
        "base_image_version": os.getenv("BASE_VERSION", "unknown"),
    }
)
s3_security_opts = {
    "ACL": "bucket-owner-full-control",
    "ServerSideEncryption": "AES256",
}
raw_data_bucket = os.environ.get("RAW_DATA_BUCKET", "")
curated_data_bucket = os.environ.get("CURATED_DATA_BUCKET", "")
log_bucket = os.environ.get("RAW_DATA_BUCKET", "")
athena_load_lambda = os.environ.get("ATHENA_LOAD_LAMBDA", "")


def handler(event, context):
    data_product_to_recreate = event.get("data_product", "")
    raw_prefix = f"raw_data/{data_product_to_recreate}"
    curated_prefix = f"curated_data/database_name={data_product_to_recreate}"
    logger.info(f"Raw prefix: {raw_prefix}")
    logger.info(f"Curated prefix: {curated_prefix}")
    logger.write_log_dict_to_s3_json(bucket=log_bucket, **s3_security_opts)

    # Check data product has associated raw data
    raw_pages = get_data_product_pages(
        bucket=raw_data_bucket,
        data_product_prefix=raw_prefix,
    )

    # Find extraction timestamps in the raw area, and not in the curated area
    paginator = s3.get_paginator("list_objects_v2")
    curated_pages = paginator.paginate(
        Bucket=curated_data_bucket, Prefix=curated_prefix
    )

    # key = "raw_data/data_product/table/extraction_timestamp=timestamp/file.csv"
    raw_table_timestamps = get_raw_data_unique_extraction_timestamps(raw_pages)

    curated_table_timestamps = set()
    for item in curated_pages.search("Contents"):
        # key = "curated_data/database_name=data_product/table_name=table"
        #       + "/extraction_timestamp=timestamp/file.parquet"
        if item["Size"] > 0:
            data_product = search_string_for_regex(
                string=item["Key"], regex=database_name_regex()
            )

            table = search_string_for_regex(
                string=item["Key"], regex=table_name_regex()
            )

            extraction_timestamp = search_string_for_regex(
                string=item["Key"], regex=extraction_timestamp_regex()
            )

            # Both sets need the same formatting to compare them
            curated_table_timestamps.add(
                f"{data_product}/{table}/{extraction_timestamp}"
            )

    timestamps_to_resync = raw_table_timestamps - curated_table_timestamps
    raw_keys_to_resync = [
        item["Key"]
        for timestamp in timestamps_to_resync
        for item in raw_pages.search("Contents")
        if timestamp in item["Key"]
    ]
    logger.info(f"raw keys to resync: {raw_keys_to_resync}")

    # Feed unprocessed data files through the load process again.
    # If there are over 1000 files, the lambda will get jammed up
    aws_lambda = boto3.client("lambda")
    for key in raw_keys_to_resync:
        payload = f'{{"detail":{{"bucket":{{"name":"{raw_data_bucket}"}}, "object":{{"key":"{key}"}}}}}}'
        aws_lambda.invoke(
            FunctionName=athena_load_lambda, InvocationType="Event", Payload=payload
        )

    logger.info(
        f"data product {data_product_to_recreate} resynced with {len(raw_keys_to_resync)} files"
    )
    logger.info(str(raw_keys_to_resync))
    logger.write_log_dict_to_s3_json(bucket=log_bucket, **s3_security_opts)


def get_data_product_pages(
    bucket, data_product_prefix, s3_client=s3, log_bucket=log_bucket
) -> PageIterator:
    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=data_product_prefix)
    # An empty page in the paginator only happens when no files exist
    for page in pages:
        if page["KeyCount"] == 0:
            error_text = f"No data product found for {data_product_prefix}"
            logger.error(error_text)
            logger.write_log_dict_to_s3_json(bucket=log_bucket, **s3_security_opts)
            raise ValueError(error_text)
    return pages


def get_raw_data_unique_extraction_timestamps(raw_pages: PageIterator) -> set:
    """
    return the unique slugs of data product, table and extraction timestamp
    designed for use with boto3's pageiterator and list_object_v2
    example key: `raw_data/data_product/table/extraction_timestamp=timestamp/file.csv`
    size > 0 because sometimes empty directories get listed in contents
    """
    return set(
        "/".join(item["Key"].split("/")[1:-1])
        for item in raw_pages.search("Contents")
        if item["Size"] > 0
    )


def search_string_for_regex(string: str, regex: str) -> str:
    """Search a string for a regex pattern and return the first result"""
    database_name_search = re.search(regex, string)
    if database_name_search:
        return database_name_search.groups()[0]
    else:
        raise ValueError(f"{regex} not found in {string}")


def database_name_regex() -> str:
    return """database_name=([^\/]*)\/"""  # noqa: W605


def table_name_regex() -> str:
    return """table_name=([^\/]*)\/"""  # noqa: W605


def extraction_timestamp_regex() -> str:
    return """(extraction_timestamp=[^\/]*)\/"""  # noqa: W605
