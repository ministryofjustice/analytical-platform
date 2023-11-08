import os
from http import HTTPStatus

from data_platform_api_responses import format_error_response, format_response_json
from data_platform_logging import DataPlatformLogger
from data_product_metadata import DataProductSchema, format_table_schema


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

    try:
        registered_glue_schema = (
            DataProductSchema(
                data_product_name=data_product_name,
                table_name=table_name,
                logger=logger,
                input_data=None,
            )
            .load()
            .latest_version_saved_data
        )
    except Exception:
        message = f"no existing table schema found in S3 for {table_name=} {data_product_name=}"
        logger.info(message)
        return format_error_response(HTTPStatus.NOT_FOUND, event, message)

    registered_schema = format_table_schema(registered_glue_schema)

    return format_response_json(status_code=HTTPStatus.OK, body=registered_schema)
