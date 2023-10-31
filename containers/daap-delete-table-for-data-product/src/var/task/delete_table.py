import os
from http import HTTPStatus

import boto3
from botocore.exceptions import ClientError
from data_platform_api_responses import format_error_response
from data_platform_logging import DataPlatformLogger
from data_platform_paths import DataProductElement, get_metadata_bucket
from data_product_metadata import DataProductMetadata, DataProductSchema

logger = DataPlatformLogger(
    extra={
        "image_version": os.getenv("VERSION", "unknown"),
        "base_image_version": os.getenv("BASE_VERSION", "unknown"),
    }
)

s3_client = boto3.client("s3")
s3_resource = boto3.resource("s3")
glue_client = boto3.client("glue")
athena_client = boto3.client("athena")


def get_all_versions(data_product_name: str) -> list[str]:
    """Gets all versions of a given data product"""
    metadata_bucket = get_metadata_bucket()
    metadata_versions = s3_client.list_objects_v2(
        Bucket=metadata_bucket, Prefix=data_product_name + "/"
    )
    # This is the case in which the data product is new.
    if not metadata_versions.get("Contents"):
        return ["v1.0"]

    versions = [
        version["Key"].split("/")[1]
        for version in metadata_versions["Contents"]
        if version["Size"] > 0
    ]

    return versions


def generate_all_element_version_prefixes(
    path_prefix: str, data_product_name: str, table_name: str
) -> list[str]:
    """Generates element prefixes for all data product versions"""
    data_product_versions = get_all_versions(data_product_name)
    element_prefixes = []

    for version in data_product_versions:
        element_prefixes.append(
            f"{path_prefix}/{data_product_name}/{version}/{table_name}/"
        )

    return element_prefixes


def delete_all_element_version_data_files(data_product_name: str, table_name: str):
    """Deletes raw and curated data for all element versions"""
    # Proceed to delete the raw data
    element = DataProductElement.load(
        element_name=table_name, data_product_name=data_product_name
    )
    raw_prefixes = generate_all_element_version_prefixes(
        "raw", data_product_name, table_name
    )
    curated_prefixes = generate_all_element_version_prefixes(
        "curated", data_product_name, table_name
    )

    s3_recursive_delete(element.data_product.raw_data_bucket, raw_prefixes)
    s3_recursive_delete(element.data_product.curated_data_bucket, curated_prefixes)


def s3_recursive_delete(bucket_name: str, prefixes: list[str]) -> None:
    """Delete all files from a prefix in s3"""
    bucket = s3_resource.Bucket(bucket_name)
    for prefix in prefixes:
        bucket.objects.filter(Prefix=prefix).delete()


def delete_glue_table(
    data_product_name: str, table_name: str, event: dict
) -> str | None:
    """Attempts to locate and delete a glue table for the given data product"""
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
    return


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
    glue_error = delete_glue_table(
        data_product_name=data_product_name, table_name=table_name, event=event
    )
    if glue_error is not None:
        return glue_error

    # Delete a given elements raw and curated data for all versions of the data product
    delete_all_element_version_data_files(
        data_product_name=data_product_name, table_name=table_name
    )

    msg = f"Successfully deleted table '{table_name}' and raw & curated data files"
    logger.info(msg)
    return format_error_response(HTTPStatus.OK, event, msg)
