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

glue_client = boto3.client("glue")


def handler(event, context, glue_client=glue_client):
    try:
        database = event["queryStringParameters"]["database"]
        table = event["queryStringParameters"]["table"]
    except KeyError:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "error": {
                        "message": "Missing required parameters: expected `database` and `table`."
                    }
                }
            ),
        }

    logger.info(f"event: {event}")
    logger.add_extras(
        {
            "lambda_name": context.function_name,
            "data_product_name": database,
            "table_name": table,
        }
    )

    try:
        resp = glue_client.get_table(DatabaseName=database, Name=table)
    except glue_client.exceptions.EntityNotFoundException:
        return {
            "statusCode": 404,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "error": {
                        "message": f"Table {table} in database {database} does not exist in the glue catalog."
                    }
                }
            ),
        }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(resp, default=str),
    }
