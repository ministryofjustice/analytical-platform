import json
import os
from http import HTTPStatus

import boto3
from data_platform_api_responses import format_error_response, format_response_json
from data_platform_logging import DataPlatformLogger
from data_product_metadata import DataProductMetadata, InvalidUpdate

s3_client = boto3.client("s3")


logger = DataPlatformLogger(
    extra={
        "image_version": os.getenv("VERSION", "unknown"),
        "base_image_version": os.getenv("BASE_VERSION", "unknown"),
    }
)


def handler(event, context):
    data_product_name = event["pathParameters"].get("data-product-name")
    table_name = event["pathParameters"].get("table-name")
    logger.add_extras(
        {
            "data_product_name": data_product_name,
            "table_name": table_name,
        }
    )
    logger.info(f"event: {event}")

    try:
        body = json.loads(event["body"])
        data_product_metadata = DataProductMetadata(
            data_product_name, logger, body["metadata"]
        )
    except KeyError:
        return format_error_response(
            response_code=HTTPStatus.BAD_REQUEST,
            event=event,
            message="Body JSON must contain a metadata object",
        )

    try:
        data_product_metadata.load().create_new_version()
    except InvalidUpdate as exception:
        logger.error("Unable to update the data product", exc_info=exception)
        return format_error_response(
            response_code=HTTPStatus.BAD_REQUEST,
            event=event,
            message="Update not allowed",
        )

    return format_response_json(
        status_code=HTTPStatus.OK, body={"version": data_product_metadata.version}
    )
