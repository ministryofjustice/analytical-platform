import json
import os
from enum import Enum
from typing import Optional

from data_platform_logging import DataPlatformLogger
from data_product_metadata import DataProductMetadata


class HTTPStatus(Enum):
    SUCCESS = 200
    CREATED = 201
    BAD_REQUEST = 400
    NOT_FOUND = 404
    METHOD_NOT_ALLOWED = 405
    CONFLICT = 409


def handler(event, context):
    """
    Handles requests that are passed through the Amazon API Gateway data-platform/register REST API endpoint.
    POST requests result in a success code to report that the product has been registered
    (metadata has been created).
    GET, PUT, and DELETE requests result in a 405 response.

    Body: 'metadata' must be sent in the request body, encoded as JSON, following the
          [spec](https://github.com/ministryofjustice/modernisation-platform-environments/blob/main/terraform/environments/data-platform/data-product-metadata-json-schema/v1.0.0/moj_data_product_metadata_spec.json)

    :param event: The event dict sent by Amazon API Gateway that contains all of the
                  request data.
    :param context: The context in which the function is called.
    :return: A response that is sent to Amazon API Gateway, to be wrapped into
             an HTTP response. The 'statusCode' field is the HTTP status code
             and the 'body' field is the body of the response.
    """

    logger = DataPlatformLogger(
        extra={
            "image_version": os.getenv("VERSION", "unknown"),
            "base_image_version": os.getenv("BASE_VERSION", "unknown"),
        }
    )

    def format_response(response_code: int, event: dict, body_dict: dict) -> dict:
        """
        Generate a response to return to API Gateway that contains the initial event,
        response code, and contents of the response body
        (i.e. body['message'] or body['error']['message'])
        """
        response_body = {"input": event}
        response_body.update(body_dict)
        response = {
            "statusCode": response_code,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(response_body),
        }
        return response

    logger.info(f"event: {event}")
    response_code = HTTPStatus.SUCCESS.value
    response_body = {}
    data_product_name = None

    http_method = event.get("httpMethod")
    event_body = json.loads(event.get("body"))

    try:
        data_product_name = event_body["metadata"]["name"]
    except KeyError:
        response_code = HTTPStatus.BAD_REQUEST.value
        error = "Data product name is missing, it must be specified in the metadata against the 'name' key"  # noqa E501
        response_body = {"error": {"message": error}}
        logger.error(error)
        return format_response(response_code, event, response_body)

    logger.add_extras({"data_product_name": data_product_name})

    if http_method == "POST":
        pass
    else:
        error = f"Sorry, {http_method} isn't allowed."
        response_body = {"error": {"message": error}}
        response_code = HTTPStatus.METHOD_NOT_ALLOWED.value
        logger.error(error)
        return format_response(response_code, event, response_body)

    data_product_metadata = DataProductMetadata(data_product_name, logger)

    if not data_product_metadata.metadata_exists:
        data_product_metadata.validate(event_body["metadata"])

        if data_product_metadata.valid_metadata:
            data_product_metadata.write_json_to_s3()
            response_code = HTTPStatus.CREATED.value
            message = f"Data Product {data_product_name} was successfully created."
            response_body = {"message": message}
            logger.info(response_body["message"])
        else:
            response_code = HTTPStatus.BAD_REQUEST.value
            error = f"Metadata failed validation with error: {data_product_metadata.error_traceback}"  # noqa E501
            response_body = {"error": {"message": error}}
            logger.error(error)
    else:
        response_code = HTTPStatus.CONFLICT.value
        error = f"Data Product {data_product_name} already has a version 1 registered metadata."  # noqa E501
        response_body = {"error": error}
        logger.error(error)

    response = format_response(
        response_code=response_code, event=event, body_dict=response_body
    )

    logger.info(f"Response: {response}")
    return response
