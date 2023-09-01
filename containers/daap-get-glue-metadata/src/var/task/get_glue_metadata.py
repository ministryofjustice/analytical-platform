import json
import os

import boto3
from data_platform_logging import DataPlatformLogger

logger = DataPlatformLogger(
    extra={
        "image_version": os.getenv("VERSION", "unknown"),
        "base_image_version": os.getenv("BASE_VERSION", "unknown"),
    }
)


def handler(event, context):
    database = event["queryStringParameters"]["database"]
    table = event["queryStringParameters"]["table"]

    logger.add_extras(
        {
            "lambda_name": context.function_name,
            "data_product_name": database,
            "table_name": table
        }
    )

    glue_client = boto3.client("glue")
    resp = glue_client.get_table(DatabaseName=database, Name=table)

    return {"statusCode": 200, "body": json.dumps(resp, default=str)}
