import os
from typing import BinaryIO

import boto3
from create_curated_athena_table import create_curated_athena_table
from create_raw_athena_table import create_raw_athena_table
from data_platform_logging import DataPlatformLogger
from data_platform_paths import BucketPath, QueryTable, RawDataExtraction
from infer_glue_schema import GlueSchemaGenerator

athena_client = boto3.client("athena")
s3_client = boto3.client("s3")
glue_client = boto3.client("glue")


class RemoteDataFile:
    def __init__(self, path: BucketPath):
        self.path = path

    def bytes_stream(self) -> BinaryIO:
        obj = boto3.resource("s3").Object(*self.path)
        return obj.get()["Body"]


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

    extraction = RawDataExtraction.parse_from_uri(full_s3_path)
    data_product_element = extraction.element

    logger = DataPlatformLogger(
        extra={
            "image_version": os.getenv("VERSION", "unknown"),
            "base_image_version": os.getenv("BASE_VERSION", "unknown"),
            "data_product_name": data_product_element.curated_data_table.database,
            "table_name": data_product_element.curated_data_table.name,
        }
    )

    logger.info(f"file is: {full_s3_path}")

    database_name, table_name = data_product_element.raw_data_table_unique()
    bytes_stream = RemoteDataFile(extraction.path)

    metadata_types, metadata_str = GlueSchemaGenerator(logger).infer_from_raw_csv(
        bytes_stream=bytes_stream,
        table_name=table_name,
        database_name=database_name,
        table_location=extraction.path.parent,
    )

    temp_table_name = metadata_types["TableInput"]["Name"]
    temp_database_name = metadata_types["DatabaseName"]
    logger.info(f"{temp_table_name=} {temp_database_name=}")
    logger.info(f"{extraction.timestamp=} {data_product_element.curated_data_table=}")

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
        data_product_element=data_product_element,
        raw_data_table=QueryTable(database=temp_database_name, name=temp_table_name),
        extraction_timestamp=extraction.timestamp.strftime("%Y%m%dT%H%M%SZ"),
        metadata=metadata_types,
        logger=logger,
        glue_client=glue_client,
        s3_client=s3_client,
        athena_client=athena_client,
    )

    # Delete the raw string tables, which are just used as an intermediary
    glue_client.delete_table(DatabaseName=temp_database_name, Name=temp_table_name)
    logger.info(f"removed raw table data_products_raw.{temp_table_name}")
