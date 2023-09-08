"""
Utilities for constructing and parsing S3 paths for a data product,
and the corresponding athena tables.

Example for data product name "data_product", table name "table":

- Raw data is stored at: raw_data/data_product/table/extraction_timestamp=timestamp/file.csv
- Curated data is stored at:
  curated_data/database_name=data_product/table_name=table/extraction_timestamp=timestamp/file.parquet
- Athena table name for raw data is: data_products_raw.table_raw
- Athena table name for curated data is: data_product.table
"""

from __future__ import annotations

import os
import re
from datetime import datetime
from typing import NamedTuple
from uuid import UUID

import boto3

RAW_DATABASE_NAME = "data_products_raw"
EXTRACTION_TIMESTAMP_FORMAT = "%Y%m%dT%H%M%SZ"
EXTRACTION_TIMESTAMP_REGEX = re.compile(
    r"^(.*)/(extraction_timestamp=)([0-9TZ]{1,16})/(.*)$"
)


class BucketPath(NamedTuple):
    """
    A path to an object in S3
    """

    bucket: str
    key: str

    @property
    def uri(self):
        return f"s3://{self.bucket}/{self.key}"

    @property
    def parent(self):
        return BucketPath(self.bucket, os.path.dirname(self.key))

    @staticmethod
    def from_uri(uri):
        if not uri.startswith("s3://"):
            raise ValueError(uri)

        bucket, key = uri.replace("s3://", "").split("/", 1)

        return BucketPath(bucket, key)


class QueryTable(NamedTuple):
    """
    Identifies a qualified table in AWS
    """

    database: str
    name: str


def get_bucket_name() -> str:
    """
    Get the bucket name from the environment
    """
    return os.environ["BUCKET_NAME"]


def get_account_id() -> str:
    """
    Get the account ID from the environment / AWS configuration
    """
    return boto3.client("sts").get_caller_identity()["Account"]


class DataProductConfig:
    """
    Configures the name, S3 paths, and athena table names for a data product.
    """

    def __init__(self, name: str, table_name: str, bucket_name: str | None = None):
        """
        Generate all the paths based on the data product name and a table name
        """
        if bucket_name is None:
            bucket_name = get_bucket_name()

        self.name = name

        self.raw_data_prefix = BucketPath(
            bucket=bucket_name, key=os.path.join("raw_data", name, table_name) + "/"
        )

        self.curated_data_prefix = BucketPath(
            bucket_name,
            os.path.join(
                "curated_data",
                f"database_name={name}",
                f"table_name={table_name}",
            )
            + "/",
        )

        self.raw_data_table = QueryTable(
            database=RAW_DATABASE_NAME, name=f"{table_name}_raw"
        )
        self.curated_data_table = QueryTable(database=name, name=table_name)

    def raw_data_path(self, timestamp: datetime, uuid_value: UUID) -> BucketPath:
        """
        Path to the raw data extracted at a particular timestamp.
        """
        return self.extraction_config(timestamp, uuid_value).path

    @staticmethod
    def _metadata_path(data_product_name: str, bucket_name: str | None = None):
        """
        Path to the V1 metadata file
        """
        if bucket_name is None:
            bucket_name = get_bucket_name()

        key = os.path.join(
            "metadata",
            data_product_name,
            "v1.0",
            "metadata.json",
        )
        return BucketPath(bucket=bucket_name, key=key)

    @staticmethod
    def metadata_spec_path(version: str, bucket_name: str | None = None) -> BucketPath:
        """
        Path to the metadata spec file
        """
        if bucket_name is None:
            bucket_name = get_bucket_name()

        return BucketPath(
            bucket_name,
            os.path.join(
                "data_product_metadata_spec",
                version,
                "moj_data_product_metadata_spec.json",
            ),
        )

    def metadata_path(self):
        """
        Path to the V1 metadata file
        """
        return DataProductConfig._metadata_path(
            data_product_name=self.name, bucket_name=self.raw_data_prefix.bucket
        )

    def extraction_config(
        self, timestamp: datetime, uuid_value: UUID
    ) -> ExtractionConfig:
        """
        Config for the data extraction identified by uuid_value and timestamp.
        """
        amz_date = timestamp.strftime(EXTRACTION_TIMESTAMP_FORMAT)

        path = BucketPath(
            bucket=self.raw_data_prefix.bucket,
            key=os.path.join(
                self.raw_data_prefix.key,
                f"extraction_timestamp={amz_date}",
                str(uuid_value),
            ),
        )

        return ExtractionConfig(
            timestamp=timestamp, data_product_config=self, path=path
        )


class ExtractionConfig:
    """
    An instance of extracting the raw data for a data product
    """

    def __init__(
        self,
        data_product_config: DataProductConfig,
        path: BucketPath,
        timestamp: datetime,
    ):
        self.data_product_config = data_product_config
        self.path = path
        self.timestamp = timestamp

    @staticmethod
    def parse_extraction_timestamp(raw_data_key: str):
        """
        Parse extraction timestamp from the raw data path
        """
        match = EXTRACTION_TIMESTAMP_REGEX.match(raw_data_key)

        if not match:
            raise ValueError(
                "Table partition extraction_timestamp is not in the expected format"
            )

        return datetime.strptime(match.group(3), EXTRACTION_TIMESTAMP_FORMAT)

    @staticmethod
    def parse_from_uri(raw_data_uri) -> ExtractionConfig:
        """
        Work out the paths from the URI of the raw data
        """
        raw_data_file = BucketPath.from_uri(raw_data_uri)

        _, data_product_name, table_name, *_rest = raw_data_file.key.split("/")

        data_product_config = DataProductConfig(
            data_product_name,
            table_name,
            bucket_name=raw_data_file.bucket,
        )

        timestamp = ExtractionConfig.parse_extraction_timestamp(raw_data_file.key)

        return ExtractionConfig(
            data_product_config=data_product_config,
            timestamp=timestamp,
            path=raw_data_file,
        )


def data_product_raw_data_file_path(
    data_product_name: str,
    table_name: str,
    extraction_timestamp: datetime,
    uuid_value: UUID,
    bucket_name: str | None = None,
) -> str:
    """
    The S3 location for the raw uploaded data.
    """
    config = DataProductConfig(
        name=data_product_name, table_name=table_name, bucket_name=bucket_name
    )
    return config.raw_data_path(
        timestamp=extraction_timestamp, uuid_value=uuid_value
    ).uri


def data_product_curated_data_prefix(
    data_product_name: str,
    table_name: str,
    bucket_name: str | None = None,
) -> str:
    """
    The S3 location for partitioned data files in parquet format.
    """
    config = DataProductConfig(
        name=data_product_name, table_name=table_name, bucket_name=bucket_name
    )

    return config.curated_data_prefix.uri


def data_product_metadata_file_path(
    data_product_name: str, bucket_name: str | None = None
) -> str:
    """
    Generate the metadata path based on the data product name
    """
    return DataProductConfig._metadata_path(
        data_product_name=data_product_name, bucket_name=bucket_name
    ).uri
