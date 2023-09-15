import os

import boto3
from create_curated_athena_table import create_curated_athena_table
from create_raw_athena_table import create_raw_athena_table
from data_platform_logging import DataPlatformLogger
from data_platform_paths import ExtractionConfig
from infer_glue_schema import infer_glue_schema

athena_client = boto3.client("athena")
s3_client = boto3.client("s3")
glue_client = boto3.client("glue")


def handler(
    event,
    context,
    athena_client=athena_client,
    s3_client=s3_client,
    glue_client=glue_client,
):
    bucket_name = event["detail"]["bucket"]["name"]
    file_key = event["detail"]["object"]["key"]
    full_s3_path = os.path.join("s3://", bucket_name, file_key)

    extraction = ExtractionConfig.parse_from_uri(full_s3_path)
    data_product = extraction.data_product_config

    logger = DataPlatformLogger(
        extra={
            "image_version": os.getenv("VERSION", "unknown"),
            "base_image_version": os.getenv("BASE_VERSION", "unknown"),
            "data_product_name": data_product.curated_data_table.database,
            "table_name": data_product.curated_data_table.name,
        }
    )

    logger.info(f"file is: {full_s3_path}")
    logger.info(
        f"config: {extraction.timestamp=} {data_product.raw_data_table=} {data_product.curated_data_table=}"
    )

    metadata_types, metadata_str = infer_glue_schema(
        extraction.path, data_product, logger=logger
    )

    # Create a table of all string-type columns, to load raw data into
    create_raw_athena_table(
        metadata_glue=metadata_str,
        logger=logger,
        glue_client=glue_client,
        bucket=extraction.path.bucket,
    )

    # Load the raw string data into the raw tables
    # Create a curated table with proper datatypes if it doesn't exist
    # Create a curated parquet file from the raw file
    # Add a timestamp and insert raw data to the curated table, casting to type
    create_curated_athena_table(
        data_product_config=data_product,
        extraction_timestamp=extraction.timestamp.strftime("%Y%m%dT%H%M%SZ"),
        metadata=metadata_types,
        logger=logger,
        glue_client=glue_client,
        s3_client=s3_client,
        athena_client=athena_client,
    )

    # Delete the raw string tables, which are just used as an intermediary
    temp_table = data_product.raw_data_table
    glue_client.delete_table(DatabaseName=temp_table.database, Name=temp_table.name)
    logger.info(f"removed raw table data_products_raw.{temp_table.name}")
