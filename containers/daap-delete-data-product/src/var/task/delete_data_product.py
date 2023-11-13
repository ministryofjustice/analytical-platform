import os
from http import HTTPStatus

import boto3
from data_platform_api_responses import format_error_response, format_response_json
from data_platform_logging import DataPlatformLogger
from data_product_metadata import DataProductMetadata
from versioning import VersionCreator

logger = DataPlatformLogger()

s3_client = boto3.client("s3")
s3_resource = boto3.resource("s3")
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

    logger.add_data_product(data_product_name)
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

    version_creator = VersionCreator(data_product_name=data_product_name, logger=logger)
    try:
        version_creator.remove_all_versions_of_data_product()
    except ValueError as e:
        return format_error_response(HTTPStatus.BAD_REQUEST, event, str(e))
    else:
        msg = f"Successfully removed data product '{data_product_name}'"
        logger.info(msg)
        return format_response_json(HTTPStatus.OK, {"message": msg})
