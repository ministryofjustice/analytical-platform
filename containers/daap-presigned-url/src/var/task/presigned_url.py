import json
import os
import uuid
from datetime import datetime

import boto3
from data_platform_logging import DataPlatformLogger
from data_platform_paths import DataProductConfig

s3 = boto3.client("s3")

logger = DataPlatformLogger(
    extra={
        "image_version": os.getenv("VERSION", "unknown"),
        "base_image_version": os.getenv("BASE_VERSION", "unknown"),
    }
)


def handler(event, context):
    bucket_name = os.environ["BUCKET_NAME"]
    database = event["queryStringParameters"]["database"]
    table = event["queryStringParameters"]["table"]
    amz_date = datetime.utcnow()
    md5 = str(event["queryStringParameters"]["contentMD5"])
    uuid_value = uuid.uuid4()

    if not isinstance(database, str) or not isinstance(table, str):
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "error": {
                        "message": "Database or table is not"
                        + " convertible to string type."
                    }
                }
            ),
        }

    data_product = DataProductConfig(
        name=database, table_name=table, bucket_name=bucket_name
    )
    file_name = data_product.raw_data_path(
        timestamp=amz_date, uuid_value=uuid_value
    ).key

    fields = {
        "x-amz-server-side-encryption": "AES256",
        "x-amz-acl": "bucket-owner-full-control",
        "x-amz-date": amz_date,
        "Content-MD5": md5,
        "Content-Type": "binary/octet-stream",
    }
    # File upload is capped at 5GB per single upload so
    # content-length-range is 5GB
    conditions = [
        {"x-amz-server-side-encryption": "AES256"},
        {"x-amz-acl": "bucket-owner-full-control"},
        {"x-amz-date": amz_date.strftime("%Y%m%dT%H%M%SZ")},
        {"Content-MD5": md5},
        ["starts-with", "$Content-MD5", ""],
        ["starts-with", "$Content-Type", ""],
        ["starts-with", "$key", file_name],
        ["content-length-range", 0, 5000000000],
    ]

    logger.add_extras(
        {
            "lambda_name": context.function_name,
            "data_product_name": database,
            "table_name": table,
        }
    )

    logger.info(f"s3 bucket: {bucket_name}")
    logger.info(f"s3 key: {file_name}")
    logger.info(f"database: {database}")
    logger.info(f"table: {table}")
    logger.info(f"amz_date: {amz_date}")
    logger.info(f"md5: {md5}")
    logger.info(f"uuid_string: {uuid_value}")
    logger.info(f"event: {event}")

    # Check the data product has been registered, ie has metadata in s3
    data_product_registration = s3.list_objects_v2(
        Bucket=data_product.metadata_path().bucket,
        Prefix=data_product.metadata_path().key,
    ).get("Contents", [])

    if not any(data_product_registration):
        return {
            "statusCode": 404,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "error": {
                        "message": "Data product registration relating"
                        + " to database not found."
                    }
                }
            ),
        }

    if any(data_product_registration):
        URL = s3.generate_presigned_post(
            Bucket=bucket_name,
            Key=file_name,
            Fields=fields,
            Conditions=conditions,
            ExpiresIn=200,
        )
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"URL": URL}, default=str),
        }
