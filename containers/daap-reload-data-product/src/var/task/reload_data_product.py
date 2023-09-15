import os
import time

import boto3
from botocore.paginate import PageIterator
from data_platform_logging import DataPlatformLogger

s3 = boto3.client("s3")
glue = boto3.client("glue")

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
athena_load_lambda = os.environ.get("ATHENA_LOAD_LAMBDA", "")


def handler(
    event,
    context,
    glue=glue,
    s3=s3,
    aws_lambda=boto3.client("lambda"),
    raw_data_bucket=raw_data_bucket,
    curated_data_bucket=curated_data_bucket,
    athena_load_lambda=athena_load_lambda,
):
    data_product_to_recreate = event.get("data_product", "")
    raw_prefix = f"raw_data/{data_product_to_recreate}"
    logger.info(f"Data product to recreate: {data_product_to_recreate}")
    logger.info(f"Raw prefix: {raw_prefix}")

    # Check data product has associated data
    data_product_pages = get_data_product_pages(
        bucket=raw_data_bucket, data_product_prefix=raw_prefix, s3_client=s3
    )

    # Drop existing athena tables for that data product
    glue_response = glue.get_tables(DatabaseName=data_product_to_recreate)
    data_product_tables = glue_response.get("TableList", [])
    if not any(data_product_tables):
        logger.info(f"No tables found for data product {data_product_to_recreate}")
    for table in data_product_tables:
        table_name = table["Name"]
        glue.delete_table(DatabaseName=data_product_to_recreate, Name=table_name)
        logger.info(f"Deleted glue table {data_product_to_recreate}.{table_name}")
    # Remove curated data files for that data product
    s3_recursive_delete(
        bucket=curated_data_bucket,
        prefix=f"curated_data/database_name={data_product_to_recreate}/",
        s3_client=s3,
    )

    # Feed all data files through the load process again. Curated files are recreated.
    count = 0
    for item in data_product_pages.search("Contents"):
        if count == 1000:
            # Wait 15 mins for other invocations to finish (max lambda duration)
            time.sleep(900)
            count = 0
        count += 1

        key = item["Key"]
        payload = f'{{"detail":{{"bucket":{{"name":"{raw_data_bucket}"}}, "object":{{"key":"{key}"}}}}}}'
        aws_lambda.invoke(
            FunctionName=athena_load_lambda, InvocationType="Event", Payload=payload
        )

    logger.info(f"data product {data_product_to_recreate} recreated")


def s3_recursive_delete(bucket, prefix, s3_client) -> None:
    """Delete all files from a prefix in s3"""
    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=prefix)

    delete_us: dict = dict(Objects=[])
    for item in pages.search("Contents"):
        delete_us["Objects"].append(dict(Key=item["Key"]))

        # delete once aws limit reached
        if len(delete_us["Objects"]) >= 1000:
            s3_client.delete_objects(Bucket=bucket, Delete=delete_us)
            delete_us = dict(Objects=[])
            logger.info(f"deleted 1000 data files from {prefix}")

    # delete remaining
    if len(delete_us["Objects"]):
        number_of_files = len(delete_us["Objects"])
        s3_client.delete_objects(Bucket=bucket, Delete=delete_us)
        logger.info(f"deleted {number_of_files} data files from {prefix}")


def get_data_product_pages(bucket, data_product_prefix, s3_client) -> PageIterator:
    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=data_product_prefix)
    # An empty page in the paginator only happens when no files exist
    for page in pages:
        if page["KeyCount"] == 0:
            error_text = f"No data product found for {data_product_prefix}"
            logger.error(error_text)
            raise ValueError(error_text)
    return pages
