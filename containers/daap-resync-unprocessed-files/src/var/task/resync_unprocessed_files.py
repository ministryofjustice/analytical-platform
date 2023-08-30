import os

import boto3
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
s3 = boto3.client("s3")


def handler(event, context):
    data_product_to_recreate = event.get("data_product", "")
    raw_prefix = f"raw_data/{data_product_to_recreate}"
    curated_prefix = f"curated_data/database_name={data_product_to_recreate}"
    logger.info(f"Raw prefix: {raw_prefix}")
    logger.info(f"Curated prefix: {curated_prefix}")
    logger.write_log_dict_to_s3_json(bucket=log_bucket, **s3_security_opts)

    # Check data product has associated data
    data_product_contents = get_data_product_contents(
        bucket=raw_data_bucket,
        data_product_prefix=raw_prefix,
    )

    # Find extraction timestamps in the raw area, and not in the curated area
    paginator = s3.get_paginator("list_objects_v2")
    raw_pages = paginator.paginate(Bucket=raw_data_bucket, Prefix=raw_prefix)
    curated_pages = paginator.paginate(
        Bucket=curated_data_bucket, Prefix=curated_prefix
    )

    # key = "raw_data/data_product/table/extraction_timestamp=timestamp/file.csv"
    raw_table_timestamps = set(
        "/".join(item["Key"].split("/")[1:4])
        for item in raw_pages.search("Contents")
        if item["Size"] > 0
    )

    curated_table_timestamps = set()
    for item in curated_pages.search("Contents"):
        # key = "curated_data/database_name=data_product/table_name=table"
        #       + "/extraction_timestamp=timestamp/file.parquet"
        if item["Size"] > 0:
            key_parts = item["Key"].split("/")
            data_product = key_parts[1].split("=")[1]
            table = key_parts[2].split("=")[1]
            # Both sets need the same formatting to compare them
            curated_table_timestamps.add(f"{data_product}/{table}/{key_parts[3]}")

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


def get_data_product_contents(
    bucket, data_product_prefix, s3_client=s3, log_bucket=log_bucket
) -> list[dict]:
    s3_response = s3_client.list_objects_v2(Bucket=bucket, Prefix=data_product_prefix)
    data_product_contents = s3_response.get("Contents", [])
    if not any(data_product_contents):
        error_text = f"No data product found for {data_product_prefix}"
        logger.error(error_text)
        logger.write_log_dict_to_s3_json(bucket=log_bucket, **s3_security_opts)
        raise ValueError(error_text)
    return data_product_contents
