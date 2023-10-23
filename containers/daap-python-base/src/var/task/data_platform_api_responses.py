import json
import os
from http import HTTPStatus
from warnings import warn

from data_platform_logging import DataPlatformLogger

logger = DataPlatformLogger(
    extra={
        "image_version": os.getenv("VERSION", "unknown"),
        "base_image_version": os.getenv("BASE_VERSION", "unknown"),
    }
)


def format_response_json(status_code: HTTPStatus, body: dict) -> dict:
    """
    Generate a JSON response to return to API Gateway
    """
    formatted_response_json = {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }

    return formatted_response_json


def format_error_response(response_code: HTTPStatus, event: dict, message: str) -> dict:
    """
    Generate a response to return to API Gateway that contains a formatted
    error.
    """
    response_body = {"error": {"message": message}}
    response = {
        "statusCode": response_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(response_body),
    }

    logger.error(f"code: {response_code}, error message: {message}, input: {event}")

    return response


def response_status_400(error) -> dict:
    warn(
        "replace `response_status_400(...)` with `format_error_response(HTTPStatus.BAD_REQUEST, ...)`",
        DeprecationWarning,
    )
    response_body = {"error": {"message": error}}
    formatted_response = format_response_json(HTTPStatus.BAD_REQUEST, response_body)

    return formatted_response


def response_status_403(error) -> dict:
    warn(
        "replace `response_status_403(...)` with `format_error_response(HTTPStatus.FORBIDDEN, ...)`",
        DeprecationWarning,
    )
    response_body = {"error": {"message": error}}
    formatted_response = format_response_json(HTTPStatus.FORBIDDEN, response_body)

    return formatted_response


def response_status_404(error) -> dict:
    warn(
        "replace `response_status_404(...)` with `format_error_response(HTTPStatus.NOT_FOUND, ...)`",
        DeprecationWarning,
    )
    response_body = {"error": {"message": error}}
    formatted_response = format_response_json(HTTPStatus.NOT_FOUND, response_body)

    return formatted_response


def response_status_200(message) -> dict:
    warn(
        "replace `response_status_200(...)` with `format_response_json(HTTPStatus.OK, ...)`",
        DeprecationWarning,
    )
    response_body = {"message": message}
    formatted_response = format_response_json(HTTPStatus.OK, response_body)

    return formatted_response
