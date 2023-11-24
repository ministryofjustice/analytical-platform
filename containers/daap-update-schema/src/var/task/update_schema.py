import json
from http import HTTPStatus

import boto3
from data_platform_api_responses import format_error_response, format_response_json
from data_platform_logging import DataPlatformLogger
from data_product_metadata import DataProductSchema
from versioning import InvalidUpdate, VersionManager

s3_client = boto3.client("s3")


logger = DataPlatformLogger()


def handler(event, context):
    data_product_name = event["pathParameters"].get("data-product-name")
    table_name = event["pathParameters"].get("table-name")
    logger.add_data_product(data_product_name=data_product_name, table_name=table_name)
    logger.info(f"event: {event}")

    schema = DataProductSchema(
        data_product_name=data_product_name,
        table_name=table_name,
        logger=logger,
        input_data=None,
    )

    if not schema.exists:
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
        version_manager = VersionManager(data_product_name, logger)
        # changes can be passed to a notification service once developed
        new_version, changes, copy_response = version_manager.update_schema(
            new_schema, table_name
        )
    except InvalidUpdate as exception:
        logger.error("Unable to update the data product", exc_info=exception)
        return format_error_response(
            response_code=HTTPStatus.BAD_REQUEST,
            event=event,
            message="Update not allowed",
        )

    # check if major or minor
    if not int(new_version.split(".")[0][-1]) == int(schema.version.split(".")[0][-1]):
        body_dict = {
            "version": new_version,
            "increment_type": "major",
            "changes": changes,
            **copy_response,
        }
    else:
        body_dict = {
            "version": new_version,
            "increment_type": "minor",
            "changes": changes,
        }
    return format_response_json(status_code=HTTPStatus.OK, body=body_dict)
