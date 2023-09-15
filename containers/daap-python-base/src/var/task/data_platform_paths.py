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
from dataclasses import dataclass, field
from datetime import datetime
from typing import NamedTuple
from uuid import UUID, uuid4

import boto3

RAW_DATABASE_NAME = "data_products_raw"
EXTRACTION_TIMESTAMP_FORMAT = "%Y%m%dT%H%M%SZ"
EXTRACTION_TIMESTAMP_REGEX = re.compile(
    r"^(.*)/(extraction_timestamp=)([0-9TZ]{1,16})/(.*)$"
)

# https://docs.aws.amazon.com/athena/latest/ug/tables-databases-columns-names.html
MAX_IDENTIFIER_LENGTH = 255


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


def get_raw_data_bucket() -> str:
    """
    Get the raw data bucket name from the environment
    """
    return os.environ.get("RAW_DATA_BUCKET", "") or os.environ["BUCKET_NAME"]


def get_curated_data_bucket() -> str:
    """
    Get the curated data bucket name from the environment
    """
    return os.environ.get("CURATED_DATA_BUCKET") or os.environ["BUCKET_NAME"]


def get_log_bucket() -> str:
    """
    Get the log data bucket name from the environment
    """
    return os.environ.get("LOG_BUCKET") or os.environ["BUCKET_NAME"]


def get_metadata_bucket() -> str:
    """
    Get the metadata data bucket name from the environment
    """
    return os.environ.get("METADATA_BUCKET") or os.environ["BUCKET_NAME"]


def get_landing_zone_bucket() -> str:
    """
    Get the landing zone bucket name from the environment
    """
    return os.environ.get("LANDING_ZONE_BUCKET") or os.environ["BUCKET_NAME"]


def get_account_id() -> str:
    """
    Get the account ID from the environment / AWS configuration
    """
    return boto3.client("sts").get_caller_identity()["Account"]


@dataclass
class DataProductElement:
    """
    A dataset within the data product. The curated data for each element
    is queryable in its own athena table.
    """

    name: str
    data_product: DataProductConfig

    @staticmethod
    def load(name, data_product_name):
        data_product = DataProductConfig(name=data_product_name)
        return DataProductElement(data_product=data_product, name=name)

    @property
    def raw_data_prefix(self):
        return BucketPath(
            bucket=self.data_product.raw_data_bucket,
            key=os.path.join("raw_data", self.data_product.name, self.name) + "/",
        )

    @property
    def curated_data_prefix(self):
        return BucketPath(
            self.data_product.curated_data_bucket,
            os.path.join(
                "curated_data",
                f"database_name={self.data_product.name}",
                f"table_name={self.name}",
            )
            + "/",
        )

    def raw_data_table_unique(self):
        suffix = uuid4()
        name = f"{self.name}_{suffix}_raw"
        if len(name) > MAX_IDENTIFIER_LENGTH:
            raise ValueError(f"Generated table name too long: {name}")

        return QueryTable(database=RAW_DATABASE_NAME, name=name)

    @property
    def curated_data_table(self):
        return QueryTable(database=self.data_product.name, name=self.name)

    def raw_data_path(self, timestamp: datetime, uuid_value: UUID) -> BucketPath:
        """
        Path to the raw data extracted at a particular timestamp.
        """
        return self.extraction_config(timestamp, uuid_value).path

    def extraction_config(
        self, timestamp: datetime, uuid_value: UUID
    ) -> RawDataExtraction:
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

        return RawDataExtraction(timestamp=timestamp, element=self, path=path)


@dataclass
class DataProductConfig:
    """
    Configures the name, and S3 buckets for a data product.
    """

    name: str
    landing_zone_bucket: str = field(default_factory=get_landing_zone_bucket)
    raw_data_bucket: str = field(default_factory=get_raw_data_bucket)
    curated_data_bucket: str = field(default_factory=get_curated_data_bucket)
    metadata_bucket: str = field(default_factory=get_metadata_bucket)

    @property
    def raw_data_prefix(self):
        return BucketPath(
            bucket=self.raw_data_bucket,
            key=os.path.join("raw_data", self.name) + "/",
        )

    @property
    def curated_data_prefix(self):
        return BucketPath(
            bucket=self.curated_data_bucket,
            key=os.path.join(
                "curated_data",
                f"database_name={self.name}",
            )
            + "/",
        )

    def element(self, name):
        return DataProductElement(name=name, data_product=self)

    def metadata_path(self):
        """
        Path to the V1 metadata file
        """
        key = os.path.join(
            "metadata",
            self.name,
            "v1.0",
            "metadata.json",
        )
        return BucketPath(bucket=self.metadata_bucket, key=key)

    @staticmethod
    def metadata_spec_prefix(bucket_name: str | None = None) -> BucketPath:
        """
        Path to the metadata spec files
        """
        return BucketPath(
            bucket_name or get_metadata_bucket(),
            os.path.join(
                "data_product_metadata_spec",
            ),
        )

    @staticmethod
    def metadata_spec_path(version: str, bucket_name: str | None = None) -> BucketPath:
        """
        Path to a metadata spec file
        """
        return BucketPath(
            bucket_name if bucket_name else get_metadata_bucket(),
            os.path.join(
                "data_product_metadata_spec",
                version,
                "moj_data_product_metadata_spec.json",
            ),
        )


@dataclass
class RawDataExtraction:
    """
    An instance of extracting the raw data for a data product
    """

    path: BucketPath
    timestamp: datetime
    element: DataProductElement

    @property
    def data_product_config(self):
        return self.element.data_product

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
    def parse_from_uri(raw_data_uri) -> RawDataExtraction:
        """
        Work out the paths from the URI of the raw data
        """
        raw_data_file = BucketPath.from_uri(raw_data_uri)

        _, data_product_name, table_name, *_rest = raw_data_file.key.split("/")

        data_product_config = DataProductConfig(
            data_product_name, raw_data_bucket=raw_data_file.bucket
        )

        timestamp = RawDataExtraction.parse_extraction_timestamp(raw_data_file.key)

        return RawDataExtraction(
            element=data_product_config.element(table_name),
            timestamp=timestamp,
            path=raw_data_file,
        )


def data_product_raw_data_file_path(
    data_product_name: str,
    table_name: str,
    extraction_timestamp: datetime,
    uuid_value: UUID,
) -> str:
    """
    The S3 location for the raw uploaded data.
    """
    element = DataProductConfig(name=data_product_name).element(table_name)
    return element.raw_data_path(
        timestamp=extraction_timestamp, uuid_value=uuid_value
    ).uri


def data_product_curated_data_prefix(data_product_name: str, table_name: str) -> str:
    """
    The S3 location for partitioned data files in parquet format.
    """
    element = DataProductConfig(name=data_product_name).element(table_name)

    return element.curated_data_prefix.uri


def data_product_metadata_file_path(data_product_name: str) -> str:
    """
    Generate the metadata path based on the data product name
    """
    return DataProductConfig(data_product_name).metadata_path().uri


def data_product_log_bucket_and_key(
    lambda_name: str | None = None, data_product_name: str | None = None
) -> BucketPath:
    """
    Generate the log file path based on lambda and data product name
    """
    bucket_name = get_log_bucket()

    date = datetime.now().strftime("%Y-%m-%d")
    date_time = datetime.now().strftime("%Y-%m-%dT%H:%M:%S:%f")[:-3]

    if lambda_name is not None and data_product_name is not None:
        key = os.path.join(
            "logs",
            "json",
            f"lambda_name={lambda_name}",
            f"data_product_name={data_product_name}",
            f"date={date}",
            f"{date_time}_log.json",
        )
    else:
        key = os.path.join("logs", "json", f"date={date}", f"{date_time}_log.json")
    return BucketPath(bucket=bucket_name, key=key)
