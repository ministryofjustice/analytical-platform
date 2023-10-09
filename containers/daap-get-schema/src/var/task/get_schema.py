import json
import os

import botocore
from data_platform_api_responses import format_response_json, response_status_404
from data_platform_logging import DataPlatformLogger
from data_platform_paths import DataProductConfig
from dataengineeringutils3.s3 import read_json_from_s3


def handler(event, context):
    data_product_name = event["pathParameters"]["data-product-name"]
    table_name = event["pathParameters"]["table-name"]

    logger = DataPlatformLogger(
        data_product_name=data_product_name,
        extra={
            "image_version": os.getenv("VERSION", "unknown"),
            "base_image_version": os.getenv("BASE_VERSION", "unknown"),
            "table_name": table_name,
        },
    )

    config = DataProductConfig(data_product_name)
    schema_path = config.schema_path(table_name)

    try:
        registered_schema = read_json_from_s3(schema_path.uri)
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchKey":
            message = f"Schema not found for data product '{data_product_name}', table '{table_name}'"
            logger.error(f"{message} ({schema_path.uri})")
            return response_status_404(message)
        else:
            raise

    # TODO: return an intelligible subset of the full glue metadata
    return format_response_json(
        status_code=200, json_body=json.dumps(registered_schema)
    )
