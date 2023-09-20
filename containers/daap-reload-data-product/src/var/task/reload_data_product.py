import os
import time

import boto3
from botocore.paginate import PageIterator
from data_platform_logging import DataPlatformLogger
from data_platform_paths import DataProductConfig

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


def handler(
    event,
    context,
    glue=glue,
    s3=s3,
    aws_lambda=boto3.client("lambda"),
    athena_load_lambda=os.environ.get("ATHENA_LOAD_LAMBDA", ""),
):
    data_product_name = event.get("data_product", "")
    data_product = DataProductConfig(name=data_product_name)
    raw_prefix = data_product.raw_data_prefix.key
    raw_data_bucket = data_product.raw_data_bucket
    curated_data_bucket = data_product.curated_data_bucket
    logger.info(f"Data product to recreate: {data_product.name}")
    logger.info(f"Raw prefix: {raw_prefix}")

    # Check data product has associated data
    data_product_pages = get_data_product_pages(
        bucket=raw_data_bucket, data_product_prefix=raw_prefix, s3_client=s3
    )

    # Drop existing athena tables for that data product
    glue_response = glue.get_tables(DatabaseName=data_product.name)
    data_product_tables = glue_response.get("TableList", [])
    if not any(data_product_tables):
        logger.info(f"No tables found for data product {data_product.name}")
    for table in data_product_tables:
        table_name = table["Name"]
        glue.delete_table(DatabaseName=data_product.name, Name=table_name)
        logger.info(f"Deleted glue table {data_product.name}.{table_name}")
    # Remove curated data files for that data product
    s3_recursive_delete(
        bucket=curated_data_bucket,
        prefix=data_product.curated_data_prefix.key,
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

    logger.info(f"data product {data_product_name} recreated")


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
