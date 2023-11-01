import json
import os
from http import HTTPStatus

import boto3
from data_platform_api_responses import format_error_response, format_response_json
from data_platform_logging import DataPlatformLogger
from data_product_metadata import DataProductSchema
from versioning import InvalidUpdate, VersionCreator

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
        {"data_product_name": data_product_name, "table_name": table_name}
    )
    logger.info(f"event: {event}")

    schema_exists = DataProductSchema(
        data_product_name=data_product_name,
        table_name=table_name,
        logger=logger,
        input_data=None,
    ).exists

    if not schema_exists:
        logger.error("No previous version of schema exists")
        return format_error_response(
            response_code=HTTPStatus.BAD_REQUEST,
            event=event,
            message="Schema does not exists. Cannot update schema without a previous version",
        )

    try:
        body = json.loads(event["body"])
        new_schema = body["schema"]
    except KeyError:
        return format_error_response(
            response_code=HTTPStatus.BAD_REQUEST,
            event=event,
            message="Body JSON must contain a schema object",
        )

    try:
        version_creator = VersionCreator(data_product_name, logger)
        # changes can be passed to a notification service once developed
        new_version, changes = version_creator.update_schema(new_schema, table_name)
    except InvalidUpdate as exception:
        logger.error("Unable to update the data product", exc_info=exception)
        return format_error_response(
            response_code=HTTPStatus.BAD_REQUEST,
            event=event,
            message="Update not allowed",
        )

    return format_response_json(
        status_code=HTTPStatus.OK, body={"version": new_version, "changes": changes}
    )
