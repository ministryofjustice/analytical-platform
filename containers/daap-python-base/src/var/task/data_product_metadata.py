import json
import traceback
from copy import deepcopy
from typing import Dict

import boto3
import botocore
from data_platform_logging import DataPlatformLogger
from data_platform_paths import (
    BucketPath,
    DataProductConfig,
    JsonSchemaName,
    get_latest_version,
    specification_path,
    specification_prefix,
)
from dataengineeringutils3.s3 import get_filepaths_from_s3_folder, read_json_from_s3
from jsonschema import validate
from jsonschema.exceptions import ValidationError

s3_client = boto3.client("s3")

glue_csv_table_input_template = {
    "DatabaseName": "",  # add to this from data product name pulled from api path
    "TableInput": {
        "Name": "",  # add to this from table name pulled from api path
        "Description": "",
        "Owner": "owner",
        # "Retention": 0,
        "StorageDescriptor": {
            "Columns": [],  # add to this from schema passed by user in api request body
            "Location": "",  # noqa E501 add to this once data land and timestamp generated, although could be top level bucket/data/product/version/table
            "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
            "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
            "Compressed": False,
            "NumberOfBuckets": -1,
            "SerdeInfo": {
                "SerializationLibrary": "org.apache.hadoop.hive.serde2.OpenCSVSerde",
                "Parameters": {"field.delim": ",", "escape.delim": "\\"},
            },
            "BucketColumns": [],
            "SortColumns": [],
            "Parameters": {},
            "StoredAsSubDirectories": False,
        },
        "PartitionKeys": [],
        "TableType": "EXTERNAL_TABLE",
        "Parameters": {"classification": "csv", "skip.header.line.count": "1"},
    },
}


def get_data_product_specification_path(
    spec_type: JsonSchemaName, version: None | str = None
) -> str:
    """gets path for given version or latest version of metadata and schema json schema"""

    # if version is empty we get the latest version
    if version is None:
        file_paths = get_filepaths_from_s3_folder(specification_prefix(spec_type).uri)
        versions = list(
            {i for p in file_paths for i in p.split("/") if i.startswith("v")}
        )
        versions.sort(key=lambda x: [int(y.replace("v", "")) for y in x.split(".")])
        latest_version = versions[-1]
        path = specification_path(spec_type, latest_version)
    else:
        path = specification_path(spec_type, version)

    return path.uri


class BaseJsonSchema:
    """base class for operations on json type metadata and schema for data products"""

    def __init__(
        self,
        data_product_name: str,
        logger: DataPlatformLogger,
        json_type: JsonSchemaName,
        write_bucket_path: BucketPath,
    ):
        self.data_product_name = data_product_name
        self.logger = logger
        self.valid = False
        self.type = json_type
        self.write_bucket = write_bucket_path.bucket
        self.write_key = write_bucket_path.key
        self.exists = self._check_if_metadata_or_schema_exists(
            self.write_bucket, self.write_key, self.type
        )

        if not self.exists:
            self.data_product_version = "v1.0"
            self.is_update = False
        else:
            self.data_product_version = get_latest_version(self.data_product_name)
            self.is_update = True

    def _check_if_metadata_or_schema_exists(
        self, bucket: str, key: str, json_type: JsonSchemaName
    ) -> object:
        # establish whether metadata for data product already exists
        try:
            # get head of object (if it exists)
            s3_client.head_object(Bucket=bucket, Key=key)
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "404":
                self.logger.info(f"No {json_type.value} exists for this data product")
                return False
            else:
                self.logger.error(f"Uknown error - {e}")
                raise Exception(f"Uknown error - {e}")
        else:
            self.logger.info(
                f"version 1 of {json_type.value} already exists for this data product"
            )
            return True

    def validate(
        self,
        data_to_validate: dict,
        json_schema_version: str | None = None,
    ) -> object:
        """
        validates a given dict of metadata against repsective json schema. This is used
        for both data product metadata and table schema validations.
        on successful validation of dict object it is saved to the class instance
        property which can be written to s3.
        """
        validate_against_jsonschema = read_json_from_s3(
            get_data_product_specification_path(self.type, json_schema_version)
        )
        try:
            validate(instance=data_to_validate, schema=validate_against_jsonschema)
        except ValidationError:
            self.error_traceback = traceback.format_exc()
            self.logger.error(
                f"{self.type} has failed validation with error: {self.error_traceback}"
            )
            self.valid = False
        else:
            self.logger.info(f"{self.type} has passed validation")
            self.valid = True
            if self.type.value == "metadata":
                self.data = data_to_validate
            else:
                self.data_pre_convert = data_to_validate
        return self

    def write_json_to_s3(self) -> None:
        """
        writes validated metadata or schema json files to s3
        """

        if "v1.0/" in self.write_key and self.exists:
            self.logger.error("Cannot overwrite 1st version of metadata or schema")
            return None

        if hasattr(self, "data") and self.valid:
            json_file = json.dumps(self.data)
            s3_client.put_object(
                Body=json_file,
                Bucket=self.write_bucket,
                Key=self.write_key,
                **{
                    "ACL": "bucket-owner-full-control",
                    "ServerSideEncryption": "AES256",
                },
            )
            self.logger.info(f"Data Product {self.type} written to s3")
        else:
            self.logger.error(f"{self.type} is not valid to write.")
            raise ValidationError(
                "Metadata must be validated before being written to s3."
            )

    # compare old and new metadata/schema and use
    # logic to set version scale.
    # will need new path function to reflect new version number schema and metadatas 3 paths
    def _classify_update(self):
        """infer type of increment to version, major/minor"""
        raise NotImplementedError

    # this can be passed to a path function for schema and metadata that doesn't use latest version
    # Maybe this will be better suited outside of the class.
    def _generate_new_version_number(self):
        """generate a version number to pass to get path function"""
        raise NotImplementedError


class DataProductSchema(BaseJsonSchema):
    """
    class to handle creation and updating of
    schema json files relating to data product tables
    """

    def __init__(
        self, data_product_name: str, table_name: str, logger: DataPlatformLogger
    ):
        bucket_path = BucketPath.from_uri(
            DataProductConfig(name=data_product_name).schema_path(table_name).uri
        )
        self.table_name = table_name

        super().__init__(
            data_product_name, logger, JsonSchemaName("schema"), bucket_path
        )

        if not self._does_data_product_metadata_exist():
            self.logger.error("Data product metadata not yet registered.")
            self.has_registered_data_product = False
        else:
            self.has_registered_data_product = True

    def _does_data_product_metadata_exist(self):
        """checks wheter data product for schema has metadata registered"""
        data_product_metadata_path = BucketPath.from_uri(
            DataProductConfig(name=self.data_product_name).metadata_path().uri
        )
        md_bucket = data_product_metadata_path.bucket
        md_key = data_product_metadata_path.key
        return self._check_if_metadata_or_schema_exists(
            md_bucket, md_key, JsonSchemaName("metadata")
        )

    def convert_schema_to_glue_table_input_csv(self):
        """
        convert schema passed by user to glue table input so it can be used to create an athena table
        from csv with headers.
        """
        if self.valid:
            glue_schema = deepcopy(glue_csv_table_input_template)
            parent_metadata = self._get_parent_data_product_metadata()
            glue_schema["DatabaseName"] = self.data_product_name
            glue_schema["TableInput"]["Name"] = self.table_name
            glue_schema["TableInput"]["Owner"] = parent_metadata["dataProductOwner"]
            if not parent_metadata.get("retentionPeriod", 0) == 0:
                glue_schema["TableInput"]["Retention"] = parent_metadata.get(
                    "retentionPeriod"
                )
            glue_schema["TableInput"]["Description"] = self.data_pre_convert[
                "tableDescription"
            ]

            for col in self.data_pre_convert["columns"]:
                glue_schema["TableInput"]["StorageDescriptor"]["Columns"].append(
                    {
                        "Name": col["name"],
                        "Type": col["type"],
                        "Comment": col["description"],
                    }
                )

            self.data = glue_schema
            self.logger.info("Data Product schema converted to csv glue table input")
        else:
            self.logger.error("schema not validated before attempted conversion")

        return self

    def _get_parent_data_product_metadata(self) -> Dict:
        data_product_metadata_path = BucketPath.from_uri(
            DataProductConfig(name=self.data_product_name)
            .metadata_path(version=self.data_product_version)
            .uri
        )

        metadata = read_json_from_s3(data_product_metadata_path.uri)

        return metadata


class DataProductMetadata(BaseJsonSchema):
    """
    class to handle creation and updating of
    schema json files relating to data products as a whole
    """

    def __init__(self, data_product_name: str, logger: DataPlatformLogger):
        bucket_path = BucketPath.from_uri(
            DataProductConfig(data_product_name).metadata_path().uri
        )

        super().__init__(
            data_product_name, logger, JsonSchemaName("metadata"), bucket_path
        )

    def add_auto_generated_metadata(self):
        """adds key value pairs to metadata that are not given by a user."""
        raise NotImplementedError
