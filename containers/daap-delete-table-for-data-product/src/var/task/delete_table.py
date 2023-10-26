import os
from http import HTTPStatus

import boto3
from botocore.exceptions import ClientError
from data_platform_api_responses import format_error_response
from data_platform_logging import DataPlatformLogger
from data_platform_paths import DataProductElement
from data_product_metadata import DataProductMetadata, DataProductSchema

logger = DataPlatformLogger(
    extra={
        "image_version": os.getenv("VERSION", "unknown"),
        "base_image_version": os.getenv("BASE_VERSION", "unknown"),
    }
)

s3_client = boto3.client("s3")
glue_client = boto3.client("glue")
athena_client = boto3.client("athena")


def s3_recursive_delete(bucket, prefix) -> None:
    """Delete all files from a prefix in s3"""
    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=prefix)

    delete_us: dict = dict(Objects=[])
    for item in pages.search("Contents"):
        if item is None:
            continue

        delete_us["Objects"].append(dict(Key=item["Key"]))

        # delete once aws limit reached
        if len(delete_us["Objects"]) >= 1000:
            s3_client.delete_objects(Bucket=bucket, Delete=delete_us)
            delete_us = dict(Objects=[])
            logger.info(f"deleted 1000 data files from {prefix}")

    # delete remaining
    if len(delete_us["Objects"]):
        number_of_files = len(delete_us["Objects"])
        s3_client.delete_objects(Bucket=bucket, Delete=delete_us)
        logger.info(f"deleted {number_of_files} data files from {prefix}")
        print(f"deleted {number_of_files} data files from {prefix}")


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

    # Attempt deletion of the glue table
    try:
        glue_client.get_table(DatabaseName=data_product_name, Name=table_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            error_message = f"Could not locate glue table '{table_name}' in database '{data_product_name}'"
            logger.error(error_message)
        else:
            error_message = f"Unexpected ClientError: {e.response['Error']['Code']}"
            logger.error(error_message)
        return format_error_response(HTTPStatus.BAD_REQUEST, event, error_message)
    else:
        glue_client.delete_table(DatabaseName=data_product_name, Name=table_name)

    # Proceed to delete the raw data
    element = DataProductElement.load(
        element_name=table_name, data_product_name=data_product_name
    )

    raw_bucket = element.data_product.raw_data_bucket
    curated_bucket = element.data_product.curated_data_bucket
    # Delete raw files
    s3_recursive_delete(bucket=raw_bucket, prefix=element.raw_data_prefix.key)
    # Delete curated files
    s3_recursive_delete(bucket=curated_bucket, prefix=element.curated_data_prefix.key)

    msg = f"Successfully deleted table '{table_name}' and raw & curated data files"
    logger.info(msg)
    return format_error_response(HTTPStatus.OK, event, msg)
