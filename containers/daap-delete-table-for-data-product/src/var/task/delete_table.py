import os
from http import HTTPStatus

import boto3
from botocore.exceptions import ClientError
from data_platform_api_responses import format_error_response
from data_platform_logging import DataPlatformLogger, s3_security_opts
from data_product_metadata import DataProductMetadata, DataProductSchema
from glue_utils import delete_glue_table
from versioning import VersionCreator, InvalidUpdate

logger = DataPlatformLogger(
    extra={
        "image_version": os.getenv("VERSION", "unknown"),
        "base_image_version": os.getenv("BASE_VERSION", "unknown"),
    }
)

s3_client = boto3.client("s3")
glue_client = boto3.client("glue")
athena_client = boto3.client("athena")


def handler(event, context):
    """
    Handles requests that are passed through the Amazon API Gateway data-product/ REST API endpoint.
    POST requests result in a success code to report that the product has been registered
    (metadata has been created).
    GET, PUT, and DELETE requests result in a 405 response.

    :param event: The event dict sent by Amazon API Gateway that contains all of the
                  request data.
    :param context: The context in which the function is called.
    :return: A response that is sent to Amazon API Gateway, to be wrapped into
             an HTTP response. The 'statusCode' field is the HTTP status code
             and the 'body' field is the body of the response.
    """

    data_product_name = event["pathParameters"].get("data-product-name")
    table_name = event["pathParameters"].get("table-name")

    logger.add_extras(
        {"data_product_name": data_product_name, "table_name": table_name}
    )
    logger.info(f"event: {event}")

    data_product_metadata = DataProductMetadata(
        data_product_name=data_product_name, logger=logger, input_data=None
    )
    if not data_product_metadata.exists:
        error_message = (
            f"Could not locate metadata for data product: {data_product_name}."
        )
        logger.error(error_message)
        return format_error_response(HTTPStatus.BAD_REQUEST, event, error_message)

    table_schema = DataProductSchema(
        data_product_name=data_product_name,
        table_name=table_name,
        logger=logger,
        input_data=None,
    )
    # Validate the existence of the table schema for the latest data product version
    if not table_schema.exists:
        error_message = f"Could not locate valid schema for table: {table_name}."
        logger.error(error_message)
        return format_error_response(HTTPStatus.BAD_REQUEST, event, error_message)

    metadata = data_product_metadata.load().latest_version_saved_data
    metadata["schemas"].remove(table_name)

    version_creator = VersionCreator(data_product_name=data_product_name, logger=logger)
    try:
        result = version_creator.update_metadata_remove_schema(input_data=metadata)
    except InvalidUpdate as e:
        error_message = f"Invalid Update : {str(e)}"
        logger.error(error_message)
        return format_error_response(HTTPStatus.BAD_REQUEST, event, error_message)
    except ValueError as e:
        return format_error_response(HTTPStatus.BAD_REQUEST, event, str(e))
    else:
        msg = f"Successfully deleted table '{table_name}' and raw & curated data files"
        logger.info(msg)
        return format_error_response(HTTPStatus.OK, event, msg)
