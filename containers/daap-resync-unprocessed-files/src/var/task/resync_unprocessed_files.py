import os

import boto3
from botocore.paginate import PageIterator
from data_platform_logging import DataPlatformLogger
from data_platform_paths import (
    DataProductConfig,
    extract_timestamp_from_curated_path,
    extract_table_name_from_curated_path,
    extract_database_name_from_curated_path,
    get_raw_data_bucket,
    get_curated_data_bucket,
    get_log_bucket
)

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

raw_data_bucket = get_raw_data_bucket()
curated_data_bucket = get_curated_data_bucket()
log_bucket = get_log_bucket()
athena_load_lambda = os.environ.get("ATHENA_LOAD_LAMBDA", "")


def handler(event, context):
    data_product_to_recreate = event.get("data_product", "")

    data_product = DataProductConfig(
        name=data_product_to_recreate,
        raw_data_bucket=raw_data_bucket,
        curated_data_bucket=raw_data_bucket,
    )

    raw_prefix = data_product.raw_data_prefix
    curated_prefix = data_product.curated_data_prefix

    logger.info(f"Raw prefix: {raw_prefix}")
    logger.info(f"Curated prefix: {curated_prefix}")
    logger.write_log_dict_to_s3_json(bucket=log_bucket, **s3_security_opts)

    # Check data product has associated raw data
    raw_pages = get_data_product_pages(
        bucket=raw_data_bucket,
        data_product_prefix=raw_prefix,
    )

    curated_pages = get_data_product_pages(
        Bucket=curated_data_bucket, data_product_prefix=curated_prefix
    )

    raw_table_timestamps = get_unique_extraction_timestamps(raw_pages)
    curated_table_timestamps = get_curated_unique_extraction_timestamps(curated_pages)

    raw_keys_to_resync = get_resync_keys(
        raw_table_timestamps, curated_table_timestamps, raw_pages
    )
    logger.info(f"raw keys to resync: {raw_keys_to_resync}")

    # Feed unprocessed data files through the load process again.
    # If there are over 1000 files, the lambda will get jammed up
    aws_lambda = boto3.client("lambda")
    for key in raw_keys_to_resync:
        payload = f'{{"detail":{{"bucket":{{"name":"{raw_data_bucket}"}},\
        "object":{{"key":"{key}"}}}}}}'
        aws_lambda.invoke(
            FunctionName=athena_load_lambda, InvocationType="Event", Payload=payload
        )

    logger.info(
        f"data product {data_product_to_recreate} resynced"
        + "with {len(raw_keys_to_resync)} files"
    )
    logger.info(str(raw_keys_to_resync))
    logger.write_log_dict_to_s3_json(bucket=log_bucket, **s3_security_opts)


def get_data_product_pages(
    bucket, data_product_prefix, s3_client=s3, log_bucket=log_bucket
) -> PageIterator:
    """ """

    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=data_product_prefix)
    # print(len(list(pages)))
    # An empty page in the paginator only happens when no files exist
    for page in pages:
        if page["KeyCount"] == 0:
            error_text = f"No data product found for {data_product_prefix}"
            logger.error(error_text)
            logger.write_log_dict_to_s3_json(bucket=log_bucket, **s3_security_opts)
            raise ValueError(error_text)
    return pages


def get_unique_extraction_timestamps(pages: PageIterator) -> set:
    """
    return the unique slugs of data product, table and extraction timestamp
    designed for use with boto3's pageiterator and list_object_v2
    example key: `key = "raw_data/data_product/table/extraction_timestamp=timestamp/file.csv`
    size > 0 because sometimes empty directories get listed in contents
    """
    filtered_pages = pages.search("Contents[?Size > `0`][]")
    result_set = set("/".join(item["Key"].split("/")[1:-1]) for item in filtered_pages)
    return result_set


def get_curated_unique_extraction_timestamps(curated_pages: PageIterator) -> set:
    """
    return the unique slugs of data product, table and extraction timestamp
    designed for use with boto3's pageiterator and list_object_v2
    example key: `key = "curated_data/database_name=data_product/table_name=table"
    + "/extraction_timestamp=timestamp/file.parquet`
    size > 0 because sometimes empty directories get listed in contents
    """
    curated_table_timestamps = set()
    for item in curated_pages.search("Contents[?Size > `0`][]"):

        data_product = extract_database_name_from_curated_path(item["Key"])

        table = extract_table_name_from_curated_path(item["Key"])

        extraction_timestamp = extract_timestamp_from_curated_path(item["Key"])

        if data_product and table and extraction_timestamp:
            data_product=data_product.replace("database_name=","")
            table=table.replace("table_name=","")
            extraction_timestamp=extraction_timestamp.replace("extraction_timestamp=","").replace("\",")
            # Both sets need the same formatting to compare them
            curated_table_timestamps.add(
                f"{data_product}{table}{extraction_timestamp}"
            )
    return curated_table_timestamps


def get_resync_keys(
    raw_table_timestamps: set, curated_table_timestamps: set, raw_pages: PageIterator
) -> list:
    """Find extraction timestamps in the raw area,
    and not in the curated area
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
