import json
import os
import re
from http import HTTPMethod, HTTPStatus

import boto3
from data_platform_api_responses import format_error_response, format_response_json
from data_platform_logging import DataPlatformLogger, s3_security_opts
from versioning import InvalidUpdate, VersionManager

s3_client = boto3.client("s3")


TABLE_NAME_REGEX = re.compile(r"\A[a-zA-Z][a-zA-Z0-9_]{1,127}\Z")


def push_to_catalogue(
    metadata: dict,
    version: str,
    data_product_name: str,
    table_name: str | None = None,
):
    lambda_client = boto3.client("lambda")

    catalogue_input = {
        "metadata": metadata,
        "version": version,
        "data_product_name": data_product_name,
        "table_name": table_name,
    }

    lambda_response = lambda_client.invoke(
        FunctionName=os.getenv("PUSH_TO_CATALOGUE_LAMBDA_ARN"),
        InvocationType="RequestResponse",
        Payload=json.dumps(catalogue_input),
    )

    catalogue_response = json.loads(lambda_response["Payload"].read().decode("utf-8"))

    return catalogue_response


def is_valid_table_name(value: str | None) -> bool:
    """
    Ensure that the name consists of alphanumeric characters and underscores,
    and is no more than 128 characters. The athena limit is 255 characters,
    so this leaves plenty of room to append suffixes to names of temporary tables
    when processing raw data.
    """
    if value is None:
        return False

    return bool(TABLE_NAME_REGEX.match(value))


def s3_copy_folder_to_new_folder(
    bucket, source_folder, latest_version, new_version, logger
):
    paginator = s3_client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(
        Bucket=bucket,
        Prefix=source_folder,
    )
    keys_to_copy = []
    try:
        for page in page_iterator:
            keys_to_copy += [item["Key"] for item in page["Contents"]]
    except KeyError as e:
        logger.error(f"metadata for folder is empty but shouldn't be: {e}")
    for key in keys_to_copy:
        copy_source = {"Bucket": bucket, "Key": key}
        destination_key = key.replace(latest_version, new_version)
        s3_client.copy(
            CopySource=copy_source,
            Bucket=bucket,
            Key=destination_key,
            ExtraArgs=s3_security_opts,
        )


def handler(event, context):
    data_product_name = event["pathParameters"].get("data-product-name")
    table_name = event["pathParameters"].get("table-name")

    if not is_valid_table_name(table_name):
        return format_error_response(
            HTTPStatus.BAD_REQUEST,
            event=event,
            message=f"Table name must match regex {TABLE_NAME_REGEX.pattern}",
        )

    logger = DataPlatformLogger(
        data_product_name=data_product_name, table_name=table_name
    )

    logger.info(f"event: {event}")

    request_body = json.loads(event.get("body"))

    http_method = event.get("httpMethod")

    if not http_method == HTTPMethod.POST:
        error_message = f"Sorry, {http_method} isn't allowed."
        logger.error(f"error message: {error_message}, input: {event}")
        return format_error_response(
            HTTPStatus.BAD_REQUEST, event=event, message=error_message
        )

    input_schema = request_body.get("schema")

    if input_schema is None:
        error_msg = (
            "a 'schema' object was not passed in the request, "
            "did you pass {table_schema} instead of {'schema': {table_schema}}?"
        )
        return format_error_response(
            HTTPStatus.BAD_REQUEST, event=event, message=error_msg
        )

    version_manager = VersionManager(data_product_name=data_product_name, logger=logger)

    try:
        new_version, schema = version_manager.create_schema(
            table_name=table_name, input_data=input_schema
        )
    except InvalidUpdate as e:
        error_message = str(e)
        if error_message.startswith(f"schema for {table_name} has failed validation:"):
            error_code = HTTPStatus.BAD_REQUEST
        else:
            error_code = HTTPStatus.FORBIDDEN
        return format_error_response(error_code, event=event, message=str(e))

    catalogue_response = push_to_catalogue(
        metadata=schema.data_pre_convert,
        version=new_version,
        data_product_name=data_product_name,
        table_name=table_name,
    )

    msg = (
        f"Schema for {table_name} has been created in the {data_product_name} Data "
        f"Product, version {new_version}"
    )
    logger.info(msg)
    return format_response_json(
        HTTPStatus.OK, {**{"message": msg}, **catalogue_response}
    )
