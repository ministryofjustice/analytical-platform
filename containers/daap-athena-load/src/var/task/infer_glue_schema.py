import copy
import os
from typing import Tuple

import boto3
import s3fs
from data_platform_logging import DataPlatformLogger
from mojap_metadata.converters.arrow_converter import ArrowConverter
from mojap_metadata.converters.glue_converter import GlueConverter
from pyarrow import csv as pa_csv
from pyarrow import parquet as pq

s3_client = boto3.client("s3")


def infer_glue_schema(
    file_key: str,
    database_name: str,
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

    bucket, key = file_key.replace("s3://", "").split("/", 1)
    table_name = key.split("/")[2].replace("table_name=", "")

    raw_table_name = f"{table_name}_raw"

    if file_type == "csv":
        # can infer schema on a sample of data, here we stream a csv as a bytes object from s3
        # at the max size and then iterate over small chunk sizes to find a full line after
        # the max sample size, which we can then read into pyarrow and infer schema.
        max_size = int(sample_size_mb * 1000000)
        start_byte = b""
        chunk_size = 5
        final_size = 0
        # the character that we'll split the data with (bytes, not string)
        # could csv dialect (newline character etc) from csv.sniffer in further dev
        newline = "\n".encode()
        obj = boto3.resource("s3").Object(bucket, key)
        bytes_stream = obj.get()["Body"]
        finished = False

        while not finished:
            if final_size == 0:
                chunk = start_byte + bytes_stream.read(max_size)
            else:
                chunk = start_byte + bytes_stream.read(chunk_size)

            if chunk == b"":
                break

            last_newline = chunk.rfind(newline)

            if last_newline == 4:
                final_size += chunk_size
                if final_size > max_size:
                    finished = True
            else:
                if final_size == 0:
                    final_size += max_size
                else:
                    final_size += chunk_size
        bytes_stream_final = obj.get(Range=f"bytes=0-{final_size-1}")["Body"]
        logger.info(f"schema inferred using {round((final_size-1)/1000000,2)}MB sample")

        # null_values has been set to an empty list as "N/A" was being read as null (in a numeric column), with
        # type inferred as int but "N/A" persiting in the csv and so failing to be cast as an int.
        # Empty list means nothing inferred as null other than null.
        arrow_table = pa_csv.read_csv(
            bytes_stream_final, convert_options=pa_csv.ConvertOptions(null_values=[])
        )
    elif file_type == "parquet" and table_type == "curated":
        curated_prefix = file_key.replace("s3://" + bucket + "/", "")
        key = s3_client.list_objects_v2(Bucket=bucket, Prefix=curated_prefix)[
            "Contents"
        ][0]["Key"]

        s3 = s3fs.S3FileSystem()

        file_path = os.path.join("s3://", bucket, key)
        arrow_table = pq.ParquetDataset(
            file_path, filesystem=s3, use_legacy_dataset=False
        )

    arrow_schema = arrow_table.schema

    ac = ArrowConverter()
    gc = GlueConverter()
    metadata_mojap = ac.generate_to_meta(arrow_schema=arrow_schema)
    metadata_mojap.name = raw_table_name
    metadata_mojap.file_format = file_type
    metadata_mojap.column_names_to_lower(inplace=True)

    for col in metadata_mojap.columns:
        if col["type"] == "null":
            col["type"] = "string"
        # no spaces or brackets are allowed in the column name
        col["name"] = col["name"].replace(" ", "_").replace("(", "").replace(")", "")

    if table_type == "curated":
        metadata_mojap.name = table_name
        metadata_mojap.columns.append(
            {"name": "extraction_timestamp", "type": "string"}
        )
        metadata_mojap.partitions = ["extraction_timestamp"]

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

    # want a schema version where all columns are string type
    metadata_glue_str = copy.deepcopy(metadata_glue)

    for i, _ in enumerate(
        metadata_glue_str["TableInput"]["StorageDescriptor"]["Columns"]
    ):
        metadata_glue_str["TableInput"]["StorageDescriptor"]["Columns"][i][
            "Type"
        ] = "string"

    return metadata_glue, metadata_glue_str
