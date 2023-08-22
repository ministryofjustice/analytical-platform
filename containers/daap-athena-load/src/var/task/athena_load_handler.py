import os
import re

import boto3
from create_curated_athena_table import create_curated_athena_table
from create_raw_athena_table import create_raw_athena_table
from data_platform_logging import DataPlatformLogger
from infer_glue_schema import infer_glue_schema

glue_client = boto3.client("glue")
athena_client = boto3.client("athena")
s3_client = boto3.client("s3")
s3_resource = boto3.resource("s3")

logger = DataPlatformLogger(
    extra={
        "image_version": os.getenv("VERSION", "unknown"),
        "base_image_version": os.getenv("BASE_VERSION", "unknown"),
    }
)

s3_security_opts = {
    "ACL": "bucket-owner-full-control",
    "ServerSideEncryption": "AES256",
}


def handler(event, context):
    bucket_name = event["detail"]["bucket"]["name"]
    file_key = event["detail"]["object"]["key"]

    full_s3_path = os.path.join("s3://", bucket_name, file_key)
    config = get_data_product_config(full_s3_path)

    logger.add_extras(
        {
            "lambda_name": context.function_name,
            "data_product_name": config["database_name"],
            "table_name": config["table_name"],
        }
    )
    logger.info(f"config: {config}")
    logger.info(f"file is: {full_s3_path}")
    metadata_types, metadata_str = infer_glue_schema(
        full_s3_path, "data_products_raw", logger=logger
    )

    # Create a table of all string-type columns, to load raw data into
    create_raw_athena_table(
        metadata_glue=metadata_str,
        logger=logger,
        glue_client=glue_client,
        bucket=bucket_name,
        s3_security_opts=s3_security_opts,
    )

    # Load the raw string data into the raw tables
    # Create a curated table with proper datatypes if it doesn't exist
    # Create a curated parquet file from the raw file
    # Add a timestamp and insert raw data to the curated table, casting to type
    create_curated_athena_table(
        config["database_name"],
        config["table_name"],
        config["table_path_curated"],
        config["bucket"],
        config["extraction_timestamp"],
        metadata=metadata_types,
        logger=logger,
        s3_security_opts=s3_security_opts,
    )

    # Delete the raw string tables, which are just used as an intermediary
    temp_table_name = config["table_name"] + "_raw"
    glue_client.delete_table(DatabaseName="data_products_raw", Name=temp_table_name)
    logger.info(f"removed raw table data_products_raw.{temp_table_name}")

    logger.write_log_dict_to_s3_json(bucket_name, **s3_security_opts)


def get_data_product_config(key: str) -> dict:
    """
    takes the raw file key and populates a config dict
    for the product
    """

    config = {}
    config["bucket"], config["key"] = key.replace("s3://", "").split("/", 1)

    config["database_name"] = key.split("/")[4]
    config["table_name"] = key.split("/")[5]
    config["table_path_raw"] = os.path.dirname(key)

    config["table_path_curated"] = (
        os.path.join(
            "s3://",
            config["bucket"],
            "curated_data",
            "database_name={}".format(config["database_name"]),
            "table_name={}".format(config["table_name"]),
        )
        + "/"
    )

    # get timestamp value
    pattern = "^(.*)\/(extraction_timestamp=)([0-9TZ]{1,16})\/(.*)$"  # noqa W605
    m = re.match(pattern, key)
    if m:
        timestamp = m.group(3)
    else:
        raise ValueError(
            "Table partition extraction_timestamp is not in the expected format"
        )
    config["extraction_timestamp"] = timestamp
    config["account_id"] = boto3.client("sts").get_caller_identity()["Account"]

    return config
