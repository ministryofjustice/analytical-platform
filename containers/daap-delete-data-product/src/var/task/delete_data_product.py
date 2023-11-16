from http import HTTPStatus

import boto3
from data_platform_api_responses import format_response_json
from data_platform_logging import DataPlatformLogger
from data_platform_paths import (
    get_curated_data_bucket,
    get_fail_data_bucket,
    get_metadata_bucket,
    get_raw_data_bucket,
)
from versioning import s3_recursive_delete

glue_client = boto3.client("glue")
logger = DataPlatformLogger()


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

    try:
        glue_client.delete_database(Name=data_product_name)
    except glue_client.exceptions.EntityNotFoundException:
        logger.info(f"Glue database '{data_product_name}' not found.")

    # Delete fail files
    s3_recursive_delete(get_fail_data_bucket(), [f"fail/{data_product_name}/"])
    # Delete raw files
    s3_recursive_delete(get_raw_data_bucket(), [f"raw/{data_product_name}/"])
    # Delete curated files
    s3_recursive_delete(get_curated_data_bucket(), [f"curated/{data_product_name}/"])
    # Delete Metadata & Schema files
    s3_recursive_delete(get_metadata_bucket(), [f"{data_product_name}/"])

    return format_response_json(
        HTTPStatus.OK,
        {"message": f"Successfully removed data product '{data_product_name}'."},
    )
