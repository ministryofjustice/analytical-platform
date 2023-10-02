import copy
import os
from io import BytesIO
from typing import BinaryIO

import boto3
from data_platform_logging import DataPlatformLogger
from data_platform_paths import BucketPath, DataProductElement
from mojap_metadata.converters.arrow_converter import ArrowConverter
from mojap_metadata.converters.glue_converter import GlueConverter
from mojap_metadata.metadata.metadata import Metadata
from pyarrow import csv as pa_csv
from pyarrow import parquet as pq

s3_client = boto3.client("s3")


class InferredMetadata:
    """
    Wrapper around the glue metadata for a table
    """

    def __init__(self, metadata_glue: dict):
        self.metadata = metadata_glue

        self.database_name = metadata_glue["DatabaseName"]
        self.table_name = metadata_glue["TableInput"]["Name"]

        self.metadata_str = self._stringify_columns(metadata_glue)

    def copy(self, database_name: str, table_name: str):
        metadata = copy.deepcopy(self.metadata)
        metadata["DatabaseName"] = database_name
        metadata["TableInput"]["Name"] = table_name
        return InferredMetadata(metadata)

    @staticmethod
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


class GlueSchemaGenerator:
    """
    Generate the glue schema from a data file
    """

    def __init__(self, logger: DataPlatformLogger):
        self.logger = logger
        self.ac = ArrowConverter()
        self.gc = GlueConverter()

    def infer_from_raw_csv(
        self,
        bytes_stream: BinaryIO,
        table_name: str,
        database_name: str,
        table_location: str,
        has_headers: bool = True,
        sample_size_mb: float = 1.5,
    ) -> InferredMetadata:
        """
        Generate schema metadata by inferring the schema of a sample of raw data (CSV)
        """
        bytes_stream_final = csv_sample(
            bytes_stream=bytes_stream,
            sample_size_in_bytes=int(sample_size_mb * 1_000_000),
            logger=self.logger,
        )

        # null_values has been set to an empty string as "N/A" was being read as null (in a numeric column), with
        # type inferred as int but "N/A" persiting in the csv and so failing to be cast as an int.
        # Empty string means nothing inferred as null other than null.
        arrow_table = pa_csv.read_csv(
            bytes_stream_final, convert_options=pa_csv.ConvertOptions(null_values=[""])
        )

        metadata_mojap = self.ac.generate_to_meta(arrow_schema=arrow_table.schema)

        self._standardise_metadata(
            metadata_mojap=metadata_mojap, table_name=table_name, file_type="csv"
        )

        metadata_glue = self.gc.generate_from_meta(
            metadata_mojap,
            database_name=database_name,
            table_location=table_location,
        )

        if has_headers:
            metadata_glue["TableInput"]["Parameters"]["skip.header.line.count"] = "1"
            metadata_glue["TableInput"]["StorageDescriptor"]["SerdeInfo"][
                "SerializationLibrary"
            ] = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

        return InferredMetadata(metadata_glue)

    def generate_from_parquet_schema(
        self,
        arrow_table: pq.ParquetDataset,
        table_name: str,
        database_name: str,
        table_location: str,
    ) -> InferredMetadata:
        """
        Generate schema metadata based on a curated parquet file.
        """
        metadata_mojap = self.ac.generate_to_meta(arrow_schema=arrow_table.schema)

        self._standardise_metadata(
            metadata_mojap=metadata_mojap, table_name=table_name, file_type="parquet"
        )

        metadata_mojap.columns.append(
            {"name": "extraction_timestamp", "type": "string"}
        )
        metadata_mojap.partitions = ["extraction_timestamp"]

        metadata_glue = self.gc.generate_from_meta(
            metadata_mojap,
            database_name=database_name,
            table_location=table_location,
        )

        return InferredMetadata(metadata_glue)

    def _standardise_metadata(
        self, metadata_mojap: Metadata, table_name: str, file_type: str
    ):
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
            col["name"] = (
                col["name"].replace(" ", "_").replace("(", "").replace(")", "")
            )


def infer_glue_schema_from_raw_csv(
    file_path: BucketPath,
    data_product_element: DataProductElement,
    logger: DataPlatformLogger,
    has_headers: bool = True,
    sample_size_mb: float = 1.5,
) -> InferredMetadata:
    """
    function infers and returns glue schema for csv
    """
    bucket, key = file_path
    file_key = file_path.uri
    inferer = GlueSchemaGenerator(logger)

    database, table_name = data_product_element.raw_data_table_unique()
    obj = boto3.resource("s3").Object(bucket, key)
    bytes_stream = obj.get()["Body"]

    return inferer.infer_from_raw_csv(
        bytes_stream=bytes_stream,
        has_headers=has_headers,
        sample_size_mb=sample_size_mb,
        table_name=table_name,
        database_name=database,
        table_location=os.path.dirname(file_key),
    )
