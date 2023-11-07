import os

import boto3
import botocore
from data_platform_logging import DataPlatformLogger, s3_security_opts
from data_platform_paths import BucketPath, RawDataExtraction, get_raw_data_bucket
from dataengineeringutils3.s3 import read_json_from_s3
from infer_glue_schema import infer_glue_schema_from_raw_csv
from validation import DataInvalid, validate_csv_format, validate_data_against_schema

s3 = boto3.client("s3")


def extract_columns_from_schema(schema: dict) -> dict[str, str]:
    """
    Extract a dict of name -> type for each column in the schema.
    """
    try:
        return {
            column["Name"]: column["Type"]
            for column in schema["TableInput"]["StorageDescriptor"]["Columns"]
        }
    except KeyError:
        raise ValueError(f"Invalid schema: {schema}")


def validate_format(bucket_name: str, file_key: str, logger: DataPlatformLogger):
    obj = boto3.resource("s3").Object(bucket_name, file_key)
    bytes_stream = obj.get()["Body"]
    validate_csv_format(bytes_stream, logger)


def handler(event, context):
    raw_data_bucket = get_raw_data_bucket()
    bucket_name = event["detail"]["bucket"]["name"]
    file_key = event["detail"]["object"]["key"]
    copy_source = {"Bucket": bucket_name, "Key": file_key}
    destination_key = file_key.replace("landing/", "raw/")
    fail_key = file_key.replace("landing/", "fail/")

    config = RawDataExtraction.parse_from_uri("s3://bucket/" + file_key)
    logger = DataPlatformLogger(
        extra={
            "image_version": os.getenv("VERSION", "unknown"),
            "base_image_version": os.getenv("BASE_VERSION", "unknown"),
            "data_product": config.element.data_product.name,
            "table": config.element.curated_data_table.name,
        }
    )
    logger.info(f"Origin bucket: {bucket_name}")
    logger.info(f"Origin key: {file_key}")
    logger.info(f"Destination bucket: {raw_data_bucket}")
    logger.info(f"Destination key: {destination_key}")

    schema_path = config.data_product_config.schema_path(table_name=config.element.name)

    try:
        registered_schema = read_json_from_s3(schema_path.uri)
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchKey":
            registered_schema = None
        else:
            raise

    if registered_schema:
        registered_schema_columns = extract_columns_from_schema(registered_schema)
        inferred_schema = infer_glue_schema_from_raw_csv(
            file_path=BucketPath(key=file_key, bucket=bucket_name),
            data_product_element=config.element,
            logger=logger,
        ).metadata
        inferred_columns = extract_columns_from_schema(inferred_schema)

        try:
            logger.info("Validating schema")
            validate_data_against_schema(
                inferred_columns=inferred_columns,
                registered_schema_columns=registered_schema_columns,
            )
            logger.info("Checking for unprocessable CSV rows")
            validate_format(bucket_name=bucket_name, file_key=file_key, logger=logger)
            logger.info("Continuing with ingestion")
        except DataInvalid:
            logger.error(f"{file_key} invalid; moving to fail location", exc_info=True)
            s3.copy(
                CopySource=copy_source,
                Bucket=raw_data_bucket,
                Key=fail_key,
                ExtraArgs=s3_security_opts,
            )
            return

    s3.copy(
        CopySource=copy_source,
        Bucket=raw_data_bucket,
        Key=destination_key,
        ExtraArgs=s3_security_opts,
    )

    s3.delete_object(Bucket=bucket_name, Key=file_key)
