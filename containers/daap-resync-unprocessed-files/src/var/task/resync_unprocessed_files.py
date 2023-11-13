import json
import os

import boto3
from botocore.paginate import PageIterator
from data_platform_logging import DataPlatformLogger
from data_platform_paths import (
    DataProductConfig,
    get_curated_data_bucket,
    get_raw_data_bucket,
)

s3 = boto3.client("s3")
logger = DataPlatformLogger()

raw_data_bucket = get_raw_data_bucket()
curated_data_bucket = get_curated_data_bucket()
athena_load_lambda = os.environ.get("ATHENA_LOAD_LAMBDA", "")


def handler(event, context):
    data_product_to_recreate = event.get("data_product", "")
    logger.add_data_product(data_product_to_recreate)

    data_product = DataProductConfig(
        name=data_product_to_recreate,
        raw_data_bucket=raw_data_bucket,
        curated_data_bucket=curated_data_bucket,
    )

    raw_prefix = data_product.raw_data_prefix.key
    curated_prefix = data_product.curated_data_prefix.key

    logger.info(f"Raw prefix: {raw_prefix}")
    logger.info(f"Curated prefix: {curated_prefix}")

    # get data product has associated raw data
    raw_pages = get_data_product_pages(
        bucket=raw_data_bucket,
        data_product_prefix=raw_prefix,
    )

    # get data product has associated curated data
    curated_pages = get_data_product_pages(
        bucket=curated_data_bucket, data_product_prefix=curated_prefix
    )

    raw_table_timestamps = get_unique_load_timestamps(raw_pages)
    curated_table_timestamps = get_unique_load_timestamps(curated_pages)

    # compare and filter the raw files to sync
    raw_keys_to_resync = get_resync_keys(
        raw_table_timestamps, curated_table_timestamps, raw_pages
    )
    logger.info(f"raw keys to resync: {raw_keys_to_resync}")

    # Feed unprocessed data files through the load process again.
    # If there are over 1000 files, the lambda will get jammed up
    aws_lambda = boto3.client("lambda")
    for key in raw_keys_to_resync:
        payload = json.dumps(
            {"detail": {"bucket": {"name": raw_data_bucket}, "object": {"key": key}}},
            indent=4,
        )
        aws_lambda.invoke(
            FunctionName=athena_load_lambda, InvocationType="Event", Payload=payload
        )

    logger.info(
        f"data product {data_product_to_recreate} resynced"
        + f"with {len(raw_keys_to_resync)} files"
    )
    logger.info(str(raw_keys_to_resync))


def get_data_product_pages(bucket, data_product_prefix, s3_client=s3) -> PageIterator:
    """returns the list of data product that are available in the bucket"""

    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=data_product_prefix)

    # An empty page in the paginator only happens when no files exist
    for page in pages:
        if page["KeyCount"] == 0:
            error_text = f"No data product found for {data_product_prefix}"
            logger.error(error_text)
            raise ValueError(error_text)
    return pages


def get_unique_load_timestamps(pages: PageIterator) -> set:
    """
    return the unique slugs of data product, table and load timestamp
    designed for use with boto3's pageiterator and list_object_v2
    example key: `key = "raw/data_product/v1.0/table/load_timestamp=timestamp/file.csv`
    size > 0 because sometimes empty directories get listed in contents
    """
    filtered_pages = pages.search("Contents[?Size > `0`][]")
    result_set = set("/".join(item["Key"].split("/")[1:-1]) for item in filtered_pages)
    return result_set


def get_resync_keys(
    raw_table_timestamps: set, curated_table_timestamps: set, raw_pages: PageIterator
) -> list:
    """
    Find load timestamps in the raw area, and not in the curated area
    """
    timestamps_to_resync = [
        item for item in raw_table_timestamps if item not in curated_table_timestamps
    ]

    raw_keys_to_resync = [
        item["Key"]
        for timestamp in timestamps_to_resync
        for item in raw_pages.search("Contents")
        if timestamp in item["Key"]
    ]
    return raw_keys_to_resync
