import json
import os

from data_platform_logging import DataPlatformLogger
from data_product_metadata import DataProductMetadata


def handler(event, context):
    logger = DataPlatformLogger(
        extra={
            "image_version": os.getenv("VERSION", "unknown"),
            "base_image_version": os.getenv("BASE_VERSION", "unknown"),
            "lambda_name": context.function_name,
        }
    )

    s3_security_opts = {
        "ACL": "bucket-owner-full-control",
        "ServerSideEncryption": "AES256",
    }

    logger.info(f"event: {event}")

    request_body = json.loads(event["body"])

    try:
        data_product_name = request_body["metadata"]["name"]
    except KeyError:
        logger.error("The name of the data product is missing from the metadata.")
        logger.write_log_dict_to_s3_json(os.environ["BUCKET_NAME"], **s3_security_opts)
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "message": "Data product name is missing, it must be specified \
                        in the metadata against the 'name' key"
                }
            ),
        }

    logger.add_extras({"data_product_name": data_product_name})

    data_product_metadata = DataProductMetadata(data_product_name, logger)

    if not data_product_metadata.metadata_exists:
        data_product_metadata.validate(request_body["metadata"])
    else:
        data_product_metadata.logger.write_log_dict_to_s3_json(
            os.environ["BUCKET_NAME"], **s3_security_opts
        )
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "data_product_name": data_product_name,
                    "message": "Your data product already has a version 1 registered metadata.",
                }
            ),
        }

    if data_product_metadata.valid_metadata:
        data_product_metadata.write_json_to_s3()
        data_product_metadata.logger.write_log_dict_to_s3_json(
            os.environ["BUCKET_NAME"], **s3_security_opts
        )
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "data_product_name": data_product_name,
                    "message": "Data product metadata has been created.",
                }
            ),
        }
    else:
        data_product_metadata.logger.write_log_dict_to_s3_json(
            os.environ["BUCKET_NAME"], **s3_security_opts
        )
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "data_product_name": data_product_name,
                    "message": f"Your metadata failed validation with \
                        this error: {data_product_metadata.error_traceback}",
                }
            ),
        }
