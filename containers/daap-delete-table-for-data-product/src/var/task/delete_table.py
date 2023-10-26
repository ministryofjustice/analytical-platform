import json
import os

import boto3
from botocore.exceptions import ClientError

from data_platform_api_responses import (
    response_status_200,
    response_status_400,
    response_status_403,
    response_status_404,
)
from data_platform_logging import DataPlatformLogger, s3_security_opts
from data_platform_paths import (
    DataProductElement,
)
from data_product_metadata import DataProductMetadata, DataProductSchema

s3_client = boto3.client("s3")
glue_client = boto3.client("glue")
athena_client = boto3.client("athena")


def delete_all_files_from_folder(bucket: str, prefix: str, logger: DataPlatformLogger):
    """Delete all files in a bucket for a given prefix"""

    paginator = s3_client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(Bucket=bucket, Prefix=prefix.key)
    results = []
    for page in page_iterator:
        results.extend(page.get("Contents"))
    logger.info(f"number of files to delete {len(results)}")

    n = 0
    CHUNK = 1000
    while n < len(results):
        files = results[n : n + CHUNK]
        objects = [{"Key": f["Key"]} for f in files]
        response = s3_client.delete_objects(Bucket=bucket, Delete={"Objects": objects})
        deleted = response.get("Deleted", [])
        errors = response.get("Errors", [])
        logger.info(f"number of files deleted {len(deleted)}")
        logger.info(f"number of deletion errors {len(errors)}")
        n += CHUNK


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
    logger = DataPlatformLogger(
        extra={
            "image_version": os.getenv("VERSION", "unknown"),
            "base_image_version": os.getenv("BASE_VERSION", "unknown"),
            "data_product_name": data_product_name,
            "table_name": table_name,
            "lambda_name": context.function_name,
        }
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
        return response_status_400(error_message)

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
        return response_status_400(error_message)

    # Attempt deletion of the glue table
    try:
        table = glue_client.get_table(DatabaseName=data_product_name, Name=table_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            error_message = f"Could not locate glue table '{table_name}' in database '{data_product_name}'"
            logger.error(error_message)
        else:
            error_message = f"Unexpected ClientError: {e.response['Error']['Code']}"
            logger.error(error_message)
        return response_status_400(error_message)
    else:
        glue_client.delete_table(DatabaseName=data_product_name, Name=table_name)

    return response_status_200("OK")
    # Proceed to delete the raw data
    element = DataProductElement.load(
        table_name=table_name, data_product_name=data_product_name
    )
    raw_bucket = element.data_product.raw_data_bucket

    # List the files in the raw bucket for the table_element prefix
    raw_files = s3_client.list_objects_v2(
        Bucket=raw_bucket, Prefix=element.raw_data_prefix.key
    )
    raw_files_to_delete = [{"Key": f["Key"]} for f in raw_files.get("Contents", [])]
    delete_object = {"Objects": raw_files_to_delete}

    raw_delete = s3_client.delete_objects(Bucket=raw_bucket, Delete=delete_object)
