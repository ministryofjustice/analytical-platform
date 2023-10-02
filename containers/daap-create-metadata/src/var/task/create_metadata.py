import json
import os

from data_platform_logging import DataPlatformLogger
from data_product_metadata import DataProductMetadata


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

    def generate_response(
        response_code: int,
        event,
        response_message: str = None,
        data_product_name: str = None,
        error: str = None,
    ) -> dict:
        response_body = {"input": event}

        if response_message:
            response_body.update({"message": response_message})
        elif error:
            response_body.update({"error": {"message": error}})

        if data_product_name is not None:
            response_body.update({"data_product_name": data_product_name})

        response = {
            "statusCode": response_code,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(response_body),
        }

        return response

    logger.info(f"event: {event}")
    response_code = 200
    response_message = None
    error = None
    data_product_name = None

    http_method = event.get("httpMethod")
    body = event.get("body")

    try:
        data_product_name = body["metadata"]["name"]
    except KeyError:
        logger.error("The name of the data product is missing from the metadata.")
        response_code = 400
        error = "Data product name is missing, it must be specified in the metadata against the 'name' key"  # noqa E501
        return generate_response(response_code, event, error=error)

    logger.add_extras({"data_product_name": data_product_name})

    data_product_metadata = DataProductMetadata(data_product_name, logger)

    if not data_product_metadata.metadata_exists:
        data_product_metadata.validate(body["metadata"])
    else:
        logger.error("Data Product metadata already exists for latest version")
        response_code = 409
        error = "Your data product already has a version 1 registered metadata."  # noqa E501

    if data_product_metadata.valid_metadata:
        data_product_metadata.write_json_to_s3()
        response_code = 201
        response_message = f"Data Product {data_product_name} was successfully created."
        logger.info(response_message)
    else:
        response_code = 400
        error = (
            f"Metadata failed validation with error: {data_product_metadata.error_traceback}",
        )  # noqa E501
        logger.error(error)

    if http_method == "POST":
        pass
    else:
        error = f"Sorry, {http_method} isn't allowed."
        response_code = 405

    response = generate_response(
        response_code,
        event,
        response_message=response_message,
        error=error,
        data_product_name=data_product_name,
    )

    logger.info(f"Response: {response}")
    return response
