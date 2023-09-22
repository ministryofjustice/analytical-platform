import copy
import os
from io import BytesIO
from typing import Tuple, BinaryIO

import boto3
import s3fs
from data_platform_logging import DataPlatformLogger
from data_platform_paths import BucketPath, DataProductElement
from mojap_metadata.converters.arrow_converter import ArrowConverter
from mojap_metadata.converters.glue_converter import GlueConverter
from mojap_metadata.metadata.metadata import Metadata
from pyarrow import csv as pa_csv
from pyarrow import parquet as pq

s3_client = boto3.client("s3")


def csv_sample(
    bytes_stream: BinaryIO,
    logger: DataPlatformLogger,
    sample_size_in_bytes: int = 1_500_000,
) -> BinaryIO:
    """
    Accepts a byte stream containing CSV and returns a new stream that aligns with the line separator, and is at least
    sample_size_in_bytes bytes.
    """
    read_bytes = bytearray()

    # the character that we'll split the data with (bytes, not string)
    # could csv dialect (newline character etc) from csv.sniffer in further dev
    newline = b"\n"

    chunk = bytes_stream.read(sample_size_in_bytes)
    read_bytes.extend(chunk)
    finished = chunk[-1:] == newline
    chunk_size = 5

    while not finished:
        chunk = bytes_stream.read(chunk_size)
        if chunk == b"":
            break

        last_newline = chunk.rfind(newline)

        if last_newline == -1:
            read_bytes.extend(chunk)
        else:
            read_bytes.extend(chunk[: last_newline + 1])
            break

    logger.info(f"extracted {round(len(read_bytes)/1000000,2)}MB sample of csv")

    return BytesIO(read_bytes)


def _standardise_metadata(metadata_mojap: Metadata, table_name: str, file_type: str):
    """
    Standardise the inferred metadata by adding table name/file type and enforcing
    naming conventions.
    """
    metadata_mojap.name = table_name
    metadata_mojap.file_format = file_type
    metadata_mojap.column_names_to_lower(inplace=True)

    for col in metadata_mojap.columns:
        if col["type"] == "null":
            col["type"] = "string"
        # no spaces or brackets are allowed in the column name
        col["name"] = col["name"].replace(" ", "_").replace("(", "").replace(")", "")


def _stringify_columns(metadata_glue: dict) -> dict:
    """
    Create a copy of the glue metadata where all columns are string type
    """
    metadata_glue_str = copy.deepcopy(metadata_glue)

    for i, _ in enumerate(
        metadata_glue_str["TableInput"]["StorageDescriptor"]["Columns"]
    ):
        metadata_glue_str["TableInput"]["StorageDescriptor"]["Columns"][i][
            "Type"
        ] = "string"

    return metadata_glue_str


def infer_glue_schema(
    file_path: BucketPath,
    data_product_element: DataProductElement,
    logger: DataPlatformLogger,
    file_type: str = "csv",
    has_headers: bool = True,
    sample_size_mb: float = 1.5,
    table_type: str = "raw",
) -> Tuple[dict, dict]:
    """
    function infers and returns glue schema for csv and parquet files.
    schema are inferred using arrow
    """
    table = (
        data_product_element.curated_data_table
        if table_type == "curated"
        else data_product_element.raw_data_table_unique()
    )
    bucket, key = file_path
    file_key = file_path.uri

    if file_type == "csv":
        # can infer schema on a sample of data, here we stream a csv as a bytes object from s3
        # at the max size and then iterate over small chunk sizes to find a full line after
        # the max sample size, which we can then read into pyarrow and infer schema.
        obj = boto3.resource("s3").Object(bucket, key)
        bytes_stream = obj.get()["Body"]

        bytes_stream_final = csv_sample(
            bytes_stream=bytes_stream,
            sample_size_in_bytes=int(sample_size_mb * 1_000_000),
            logger=logger,
        )

        # null_values has been set to an empty list as "N/A" was being read as null (in a numeric column), with
        # type inferred as int but "N/A" persiting in the csv and so failing to be cast as an int.
        # Empty list means nothing inferred as null other than null.
        arrow_table = pa_csv.read_csv(
            bytes_stream_final, convert_options=pa_csv.ConvertOptions(null_values=[])
        )
    elif file_type == "parquet" and table_type == "curated":
        # We have passed in a prefix, and need to pick a specific file
        key = s3_client.list_objects_v2(Bucket=bucket, Prefix=key)["Contents"][0]["Key"]
        file_path = os.path.join("s3://", bucket, key)

        s3 = s3fs.S3FileSystem()

        arrow_table = pq.ParquetDataset(
            file_path, filesystem=s3, use_legacy_dataset=False
        )

    arrow_schema = arrow_table.schema

    ac = ArrowConverter()
    gc = GlueConverter()
    metadata_mojap = ac.generate_to_meta(arrow_schema=arrow_schema)

    _standardise_metadata(
        metadata_mojap=metadata_mojap, table_name=table.name, file_type=file_type
    )

    if table_type == "curated":
        metadata_mojap.columns.append(
            {"name": "extraction_timestamp", "type": "string"}
        )
        metadata_mojap.partitions = ["extraction_timestamp"]

    database_name = table.database

    metadata_glue = gc.generate_from_meta(
        metadata_mojap,
        database_name=database_name,
        table_location=os.path.dirname(file_key),
    )

    if file_type == "csv" and has_headers:
        metadata_glue["TableInput"]["Parameters"]["skip.header.line.count"] = "1"
        metadata_glue["TableInput"]["StorageDescriptor"]["SerdeInfo"][
            "SerializationLibrary"
        ] = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

    metadata_glue_str = _stringify_columns(metadata_glue)

    return metadata_glue, metadata_glue_str
