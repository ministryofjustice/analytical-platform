import json
import os
from http import HTTPMethod

import boto3
from data_platform_api_responses import (
    response_status_200,
    response_status_400,
    response_status_403,
    response_status_404,
)
from data_platform_logging import DataPlatformLogger, s3_security_opts
from data_platform_paths import DataProductConfig, get_latest_version, get_new_version
from data_product_metadata import DataProductMetadata, DataProductSchema

s3_client = boto3.client("s3")


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
    logger = DataPlatformLogger(
        extra={
            "image_version": os.getenv("VERSION", "unknown"),
            "base_image_version": os.getenv("BASE_VERSION", "unknown"),
            "data_product_name": data_product_name,
            "table_name": table_name,
        }
    )

    logger.info(f"event: {event}")

    request_body = json.loads(event.get("body"))

    http_method = event.get("httpMethod")

    if not http_method == HTTPMethod.POST:
        error_message = f"Sorry, {http_method} isn't allowed."
        logger.error(f"error message: {error_message}, input: {event}")
        return response_status_400(error_message)

    schema = DataProductSchema(
        data_product_name=data_product_name,
        table_name=table_name,
        logger=logger,
        input_data=request_body.get("schema"),
    )

    if schema.exists:
        error_msg = (
            f"v1 of this schema for table {table_name} already exists. You can upversion this schema if "
            "there are changes from v1 using the PUT method of this endpoint. Or if this is a different "
            "table then please choose a different name for it."
        )
        logger.error("create schema called where v1 already exists.")
        return response_status_403(error_msg)

    if not schema.has_registered_data_product:
        error_msg = (
            f"Schema for {table_name} has no registered metadata for the data product it belongs to. "
            "Please first register the data product metadata using the POST method of the /data-product/register"
            " endpoint."
        )
        logger.error("schema has no associated registered data product metadata.")
        return response_status_403(error_msg)

    # Code below that handles verisoning of a data product will be moved to a central module eventually.

    # if schema already exist then we need to minor version increment to dataproduct metadata and schema
    if schema.valid:
        schema.convert_schema_to_glue_table_input_csv()
        if not schema.parent_product_has_registered_schema:
            metadata_dict = schema.parent_data_product_metadata
            # metadata_with_schema = metadata_dict
            metadata_dict["schemas"] = [table_name]

            # write v1 of metadata updated with registered schema, this is the only time we overwrite v1
            DataProductMetadata(
                data_product_name=data_product_name,
                logger=logger,
                input_data=metadata_dict,
            ).write_json_to_s3(
                DataProductConfig(data_product_name).metadata_path("v1.0").key
            )
            schema.write_json_to_s3(
                DataProductConfig(data_product_name).schema_path(table_name, "v1.0").key
            )
            msg = f"Schema for {table_name} has been created in the {data_product_name} data product"
            logger.info("Schema successfully created")
            return response_status_200(msg)
        else:
            # write to next minor version increment
            latest_version = get_latest_version(data_product_name=data_product_name)
            new_version = get_new_version(latest_version, "minor")
            # copy metatdata and schema to new version folder
            latest_metadata_path = DataProductConfig(data_product_name).metadata_path()
            folder = os.path.dirname(latest_metadata_path.key) + "/"

            s3_copy_folder_to_new_folder(
                bucket=latest_metadata_path.bucket,
                source_folder=folder,
                latest_version=latest_version,
                new_version=new_version,
                logger=logger,
            )

            schema_key = (
                DataProductConfig(name=data_product_name)
                .schema_path(table_name=table_name, version=new_version)
                .key
            )
            metadata_key = (
                DataProductConfig(name=data_product_name)
                .metadata_path(version=new_version)
                .key
            )
            metadata_dict = schema.parent_data_product_metadata
            metadata_dict["schemas"].append(table_name)
            DataProductMetadata(
                data_product_name=data_product_name,
                logger=logger,
                input_data=metadata_dict,
            ).write_json_to_s3(write_key=metadata_key)
            schema.write_json_to_s3(write_key=schema_key)
            msg = f"Schema for {table_name} has been created in the {data_product_name} data product"
            logger.info("Schema successfully created")
            return response_status_200(msg)
    else:
        error_msg = f"schema for {table_name} has failed validation with the following error: {schema.error_traceback}"
        return response_status_400(error_msg)
