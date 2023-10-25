"""
Utilities for constructing and parsing S3 paths for a data product,
and the corresponding athena tables.

Example for data product name "data_product", table name "table":

- Raw data is stored at: raw/{data-product}/{version}/{table}/load_timestamp={load_timestamp}/data.ext
- Curated data is stored at: curated/{data-product}/{version}/{table}/load_timestamp={load_timestamp}/data.ext
- Athena table name for curated data is: data_product.table
- Athena table name for raw data has the format: data_products_raw.table_data_3d95ff89_b063_484d_b510_53742d0a6a64_raw
"""

from __future__ import annotations

import logging
import os
import re
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import NamedTuple
from uuid import UUID, uuid4

import boto3

s3 = boto3.client("s3")

RAW_DATABASE_NAME = "data_products_raw"
LOAD_TIMESTAMP_FORMAT = "%Y%m%dT%H%M%SZ"
LOAD_TIMESTAMP_REGEX = re.compile(r"^(.*)/(load_timestamp=)([0-9TZ]{1,16})/(.*)$")
LOAD_TIMESTAMP_CURATED_REGEX = re.compile(r"load_timestamp=([^/]+)")

DATABASE_NAME_REGEX = re.compile(r"database_name=([^\/]*)\/")
TABLE_NAME_REGEX = re.compile(r"table_name=([^\/]*)\/")

# https://docs.aws.amazon.com/athena/latest/ug/tables-databases-columns-names.html
MAX_IDENTIFIER_LENGTH = 255


class JsonSchemaName(Enum):
    """
    Class to identify different types of metadata associated with a data product.

    data product metadata - relates to data of the data product as a whole. Can be 1 or more tables.

    and

    data product schema - relates to data describing a table within a data product.
    """

    data_product_metadata: str = "metadata"
    data_product_schema: str = "schema"

    @classmethod
    def _missing_(cls, value):
        raise ValueError(
            "%r is not a valid %s.  Valid types: %s"
            % (
                value,
                cls.__name__,
                ", ".join([repr(m.value) for m in cls]),
            )
        )


def specification_prefix(
    spec_type: JsonSchemaName, bucket_name: str | None = None
) -> BucketPath:
    """
    Path to prefix of the schema or metadata specification json schema, before version.
    """
    return BucketPath(
        bucket_name or get_metadata_bucket(),
        os.path.join(
            f"{spec_type.name}_spec",
        ),
    )


def specification_path(
    spec_type: JsonSchemaName, version: str, bucket_name: str | None = None
) -> BucketPath:
    """
    Full path to a schema or metadata specifciation json schema.
    """
    return BucketPath(
        bucket_name if bucket_name else get_metadata_bucket(),
        os.path.join(
            f"{spec_type.name}_spec",
            version,
            f"moj_{spec_type.name}_spec.json",
        ),
    )


def get_new_version(version, increment_type):
    if increment_type == "minor":
        new_version = version.split(".")[0] + "." + str(int(version.split(".")[-1]) + 1)
    elif increment_type == "major":
        new_version = "v" + str(int(version.replace("v", "").split(".")[0]) + 1) + ".0"
    return new_version


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


def search_string_for_regex(string: str, regex: re.Pattern[str]) -> str | None:
    """Search a string for a regex pattern and return the first result"""
    search_match = regex.search(string)
    if not search_match:
        logging.info(f"{regex} not found in {string}")
    return search_match.groups()[0] if search_match else None


def extract_table_name_from_curated_path(string: str):
    return search_string_for_regex(string, regex=TABLE_NAME_REGEX)


def extract_database_name_from_curated_path(string: str):
    return search_string_for_regex(string, regex=DATABASE_NAME_REGEX)


def extract_timestamp_from_curated_path(string: str):
    return search_string_for_regex(string, regex=LOAD_TIMESTAMP_CURATED_REGEX)


def get_latest_version(data_product_name: str):
    """Get the latest version of a data product, else return v1.0"""
    metadata_bucket = get_metadata_bucket()
    metadata_versions = s3.list_objects_v2(
        Bucket=metadata_bucket, Prefix=data_product_name + "/"
    )
    # This is the case in which the data product is new.
    if not metadata_versions.get("Contents"):
        return "v1.0"

    versions = [
        version["Key"].split("/")[1]
        for version in metadata_versions["Contents"]
        if version["Size"] > 0
    ]
    versions.sort(key=lambda x: [int(y.replace("v", "")) for y in x.split(".")])
    latest_version = versions[-1]

    return latest_version


@dataclass
class DataProductElement:
    """
    An entity within the data product. The curated data for each element
    is queryable in its own athena table.
    """

    name: str
    data_product: DataProductConfig

    @staticmethod
    def load(element_name, data_product_name):
        data_product = DataProductConfig(name=data_product_name)
        return DataProductElement(data_product=data_product, name=element_name)

    @property
    def landing_data_prefix(self):
        """
        The path to the raw data in s3 up to and including the element name,
        e.g. landing/{data-product}/{version}/{some_element}
        """
        return BucketPath(
            bucket=self.data_product.landing_zone_bucket,
            key=os.path.join(self.data_product.landing_data_prefix.key, self.name)
            + "/",
        )

    @property
    def raw_data_prefix(self):
        """
        The path to the raw data in s3 up to and including the element name,
        e.g. raw/{data-product}/{version}/{some_element}
        """
        return BucketPath(
            bucket=self.data_product.raw_data_bucket,
            key=os.path.join(self.data_product.raw_data_prefix.key, self.name) + "/",
        )

    @property
    def curated_data_prefix(self):
        """
        The path to the curated data in s3 up to and including the element name,
        e.g. curated/{data-product}/{version}/{some-element}/
        """
        return BucketPath(
            bucket=self.data_product.curated_data_bucket,
            key=os.path.join(
                self.data_product.curated_data_prefix.key,
                self.name,
            )
            + "/",
        )

    def raw_data_table_unique(self):
        """
        A unique table name to use for querying raw data via athena.
        These tables are always temporary.
        E.g. ('data_products_raw', 'some_element_3d95ff89-b063-484d-b510-53742d0a6a64_raw)
        """
        suffix = uuid4()
        name = f"{self.name}_{suffix}_raw".replace("-", "_")
        if len(name) > MAX_IDENTIFIER_LENGTH:
            raise ValueError(f"Generated table name too long: {name}")

        return QueryTable(database=RAW_DATABASE_NAME, name=name)

    @property
    def curated_data_table(self):
        """
        The name of the athena table for the data product element.
        E.g. ('my_data_product', 'some_element')
        """
        return QueryTable(database=self.data_product.name, name=self.name)

    def raw_data_path(
        self, timestamp: datetime, uuid_value: UUID, file_extension: str
    ) -> BucketPath:
        """
        Path to the raw data extracted at a particular timestamp.
        E.g. raw_data/my-data-product/some-element/load_timestamp=
             20230101T000000Z/3d95ff89-b063-484d-b510-53742d0a6a64.csv
        """
        return self.extraction_instance(timestamp, uuid_value, file_extension).path

    def landing_data_path(
        self, timestamp: datetime, uuid_value: UUID, file_extension: str
    ) -> BucketPath:
        """
        Path to the landing bucket location where a data file will be put
        with a presigned url, for the file to be copied to raw and deleted.
        """
        amz_date = timestamp.strftime(LOAD_TIMESTAMP_FORMAT)

        path = BucketPath(
            bucket=self.landing_data_prefix.bucket,
            key=os.path.join(
                self.landing_data_prefix.key,
                f"load_timestamp={amz_date}",
                f"{str(uuid_value)}{file_extension}",
            ),
        )

        return path

    def extraction_instance(
        self, timestamp: datetime, uuid_value: UUID, file_extension: str
    ) -> RawDataExtraction:
        """
        Instance of the data extraction identified by uuid_value and timestamp.
        """
        amz_date = timestamp.strftime(LOAD_TIMESTAMP_FORMAT)

        path = BucketPath(
            bucket=self.raw_data_prefix.bucket,
            key=os.path.join(
                self.raw_data_prefix.key,
                f"load_timestamp={amz_date}",
                f"{str(uuid_value)}{file_extension}",
            ),
        )

        return RawDataExtraction(timestamp=timestamp, element=self, path=path)


@dataclass
class DataProductConfig:
    """
    Configures the name, version, elements, S3 buckets, and related paths for a data
    product.

    A data product may contain many `data product elements`. To construct
    paths for each one, call `.element()` with the name of the element.
    """

    name: str
    landing_zone_bucket: str = field(default_factory=get_landing_zone_bucket)
    raw_data_bucket: str = field(default_factory=get_raw_data_bucket)
    curated_data_bucket: str = field(default_factory=get_curated_data_bucket)
    metadata_bucket: str = field(default_factory=get_metadata_bucket)

    def __post_init__(self):
        self.latest_version = get_latest_version(self.name)

    @property
    def raw_data_prefix(self):
        """
        The path to the raw data in s3 excluding the element name,
        e.g. raw/my-data-product/version/
        """
        return BucketPath(
            bucket=self.raw_data_bucket,
            key=os.path.join("raw", self.name, self.latest_version) + "/",
        )

    @property
    def landing_data_prefix(self):
        """
        The path to the landing data in s3 excluding the element name,
        e.g. landing/my-data-product/version/
        """
        return BucketPath(
            bucket=self.landing_zone_bucket,
            key=os.path.join("landing", self.name, self.latest_version) + "/",
        )

    @property
    def curated_data_prefix(self):
        """
        The path to the curated data in s3 excluding the element name,
        e.g. curated/my-data-product/version/
        """
        return BucketPath(
            bucket=self.curated_data_bucket,
            key=os.path.join("curated", self.name, self.latest_version) + "/",
        )

    def element(self, name):
        """
        Construct a DataProductElement object to return paths relative to
        a particular data product element identified by `name`.
        """
        return DataProductElement(name=name, data_product=self)

    def metadata_path(self, version: str | None = None) -> BucketPath:
        """
        Path to a version of a data product metadata file. If version omitted then
        latest version path is returned
        """

        if version is None:
            version = self.latest_version

        key = os.path.join(
            self.name,
            version,
            "metadata.json",
        )
        return BucketPath(bucket=self.metadata_bucket, key=key)

    def schema_path(self, table_name: str, version: str | None = None) -> BucketPath:
        """
        Path to a version of a schema file for a given table. If version omitted then
        latest version path is returned
        """

        if version is None:
            version = self.latest_version

        key = os.path.join(
            self.name,
            version,
            table_name,
            "schema.json",
        )
        return BucketPath(bucket=self.metadata_bucket, key=key)


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
    def parse_load_timestamp(raw_data_key: str):
        """
        Parse extraction timestamp from the raw data path
        """
        match = LOAD_TIMESTAMP_REGEX.match(raw_data_key)

        if not match:
            raise ValueError(
                "Table partition load_timestamp is not in the expected format"
            )

        return datetime.strptime(match.group(3), LOAD_TIMESTAMP_FORMAT)

    @staticmethod
    def parse_from_uri(raw_data_uri) -> RawDataExtraction:
        """
        Work out the paths from the URI of the raw data
        """
        raw_data_file = BucketPath.from_uri(raw_data_uri)

        _, data_product_name, version, table_name, *_rest = raw_data_file.key.split("/")

        data_product_config = DataProductConfig(
            data_product_name, raw_data_bucket=raw_data_file.bucket
        )

        timestamp = RawDataExtraction.parse_load_timestamp(raw_data_file.key)

        return RawDataExtraction(
            element=data_product_config.element(table_name),
            timestamp=timestamp,
            path=raw_data_file,
        )


def data_product_log_bucket_and_key(
    lambda_name: str | None = None,
    data_product_name: str | None = None,
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
