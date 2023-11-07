from __future__ import annotations

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
        "Owner": "",
        # "Retention": 0,
        "StorageDescriptor": {
            "Columns": [],  # add to this from schema passed by user in api request body
            "Location": "",  # noqa E501 add to this once data land and timestamp generated, although could be top level bucket/data/product/version/table
            "InputFormat": "",
            "OutputFormat": "",
            "Compressed": False,
            "NumberOfBuckets": -1,
            "SerdeInfo": {},
            "BucketColumns": [],
            "SortColumns": [],
            "Parameters": {},
            "StoredAsSubDirectories": False,
        },
        "PartitionKeys": [],
        "TableType": "EXTERNAL_TABLE",
        "Parameters": {},
    },
}


def format_table_schema(glue_schema: dict) -> dict:
    """reformats a glue table schema into the metadata ingestion specification.

    Args:
        glue_schema (dict): Schema in Glue-compatible format

    Returns:
        dict: Schema in original ingested metadata format
    """
    table_input = glue_schema["TableInput"]
    columns = table_input["StorageDescriptor"]["Columns"]

    return {
        "tableDescription": table_input.get("Description"),
        "columns": [
            {
                "name": column["Name"],
                "type": column["Type"],
                "description": column.get("Comment"),
            }
            for column in columns
        ],
    }


def get_data_product_specification_path(
    spec_type: JsonSchemaName, version: None | str = None
) -> str:
    """
    Gets the specification path for the JSON schema that validates a data product metadata
    or table schema. If a version is not specified, the latest JSON schema version is assumed.
    """

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
    """
    Base class for operations on json type metadata and schema for data products.

    Parameters:
    - latest_version_path should be the path to the latest version, or 1.0.0 if no version exists
    - input_data is optional data to be validated and written

    Attributes:
    - exists: does *any* version of this schema exist?
    - valid: is the input_data valid?
    - version: the version string corresponding to the `latest_version_path`
    - write_bucket / latest_version_key: the bucket and key components of `latest_version_path`, respectively
    - latest_version_saved_data: the metadata stored at `latest_version_path`
    """

    def __init__(
        self,
        data_product_name: str,
        logger: DataPlatformLogger,
        json_type: JsonSchemaName,
        latest_version_path: BucketPath,
        input_data: dict | None,
        table_name: str | None = None,
    ):
        self.data_product_name = data_product_name
        if table_name is not None:
            self.table_name = table_name
        self.logger = logger
        self.valid = False
        self.type = json_type
        self.exists = self._check_a_version_exists()
        self.write_bucket = latest_version_path.bucket
        self.latest_version_key = latest_version_path.key
        self.version = latest_version_path.key.split("/")[1]
        self.database_name = self.data_product_name + "_" + self.version.split(".")[0]
        if input_data is not None:
            self.validate(input_data)

    def _check_a_version_exists(self) -> object:
        """checks a version of json file exists of the given input data"""
        if self.type == JsonSchemaName.data_product_schema:
            bucket_path = DataProductConfig(name=self.data_product_name).schema_path(
                table_name=self.table_name
            )

        elif self.type == JsonSchemaName.data_product_metadata:
            bucket_path = DataProductConfig(name=self.data_product_name).metadata_path()
        # establish whether metadata for data product already exists
        try:
            # get head of object (if it exists)
            s3_client.head_object(Bucket=bucket_path.bucket, Key=bucket_path.key)
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "404":
                self.logger.info(f"No {self.type.value} exists for this data product")
                return False
            else:
                self.logger.error(f"Uknown error - {e}")
                raise Exception(f"Uknown error - {e}")
        else:
            self.logger.info(
                f"version 1 of {self.type.value} already exists for this data product"
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

    def write_json_to_s3(self, write_key: str) -> None:
        """
        writes validated metadata or schema json files to s3
        """

        if hasattr(self, "data") and self.valid:
            json_file = json.dumps(self.data)
            s3_client.put_object(
                Body=json_file,
                Bucket=self.write_bucket,
                Key=write_key,
                **{
                    "ACL": "bucket-owner-full-control",
                    "ServerSideEncryption": "AES256",
                },
            )
            self.logger.info(
                f"Data Product {self.type} written to s3 at {self.write_bucket}/{write_key}"
            )
        else:
            self.logger.error(f"{self.type} is not valid to write.")
            raise ValidationError(
                "Metadata must be validated before being written to s3."
            )

    def load(self):
        """loads the latest version of json file saved in s3"""
        if self.exists:
            self.latest_version_saved_data = read_json_from_s3(
                f"s3://{self.write_bucket}/{self.latest_version_key}"
            )
        else:
            self.logger.error("There is no metadata to load")
        return self

    def changed_fields(self) -> set[str]:
        """
        Return a set of fields that have changed between the last load
        and the input_data.
        """
        if self.type == JsonSchemaName.data_product_schema:
            latest_version = format_table_schema(self.latest_version_saved_data)
            new_version = self.data_pre_convert
        else:
            latest_version = self.latest_version_saved_data
            new_version = self.data

        if not latest_version or not new_version:
            return set()

        changed_fields = set()
        for field in new_version:
            if new_version[field] == latest_version[field]:
                continue

            changed_fields.add(field)

        return changed_fields


class DataProductSchema(BaseJsonSchema):
    """
    class to handle creation and updating of
    schema json files relating to data product tables
    """

    def __init__(
        self,
        data_product_name: str,
        table_name: str,
        logger: DataPlatformLogger,
        input_data: dict | None,
    ):
        # returns path of latest schema or v1 if it doesn't exist
        latest_version_path = DataProductConfig(name=data_product_name).schema_path(
            table_name
        )

        super().__init__(
            data_product_name=data_product_name,
            logger=logger,
            json_type=JsonSchemaName("schema"),
            latest_version_path=latest_version_path,
            input_data=input_data,
            table_name=table_name,
        )

        if not self._does_data_product_metadata_exist():
            self.logger.error("Data product metadata not yet registered.")
            self.has_registered_data_product = False
        else:
            self.has_registered_data_product = True
            self.parent_data_product_metadata = (
                DataProductMetadata(
                    data_product_name=self.data_product_name,
                    logger=self.logger,
                    input_data=None,
                )
                .load()
                .latest_version_saved_data
            )

        self.parent_product_has_registered_schema = (
            self._does_data_product_have_other_schema_registered()
        )

    def _does_data_product_metadata_exist(self):
        """checks whether data product for schema has metadata registered"""
        metadata = DataProductMetadata(
            data_product_name=self.data_product_name,
            logger=self.logger,
            input_data=None,
        )
        return metadata.exists

    def _does_data_product_have_other_schema_registered(self):
        """
        the data product metadata needs a minor version increment if a table schema is added and
        one or more schema already exist in the data product
        """
        if (
            self.has_registered_data_product
            and "schemas" in self.parent_data_product_metadata.keys()
        ):
            return True
        else:
            return False

    def convert_schema_to_glue_table_input_csv(self):
        """
        convert schema passed by user to glue table input so it can be used to create an athena table
        from csv with headers.
        """
        # noqa E501  limits: https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-catalog-tables.html#aws-glue-api-catalog-tables-Column
        glue_comment_char_limit = 255
        glue_desc_char_limit = 2048

        if self.valid:
            glue_schema = deepcopy(glue_csv_table_input_template)
            parent_metadata = self.parent_data_product_metadata
            glue_schema["DatabaseName"] = self.database_name
            glue_schema["TableInput"]["Name"] = self.table_name
            glue_schema["TableInput"]["Owner"] = parent_metadata["dataProductOwner"]
            # if not parent_metadata.get("retentionPeriod", 0) == 0:
            glue_schema["TableInput"]["Retention"] = parent_metadata.get(
                "retentionPeriod"
            )
            glue_schema["TableInput"][
                "Description"
            ] = f"{self.data_pre_convert['tableDescription']:.{glue_desc_char_limit}}"

            for col in self.data_pre_convert["columns"]:
                glue_schema["TableInput"]["StorageDescriptor"]["Columns"].append(
                    {
                        "Name": col["name"],
                        "Type": col["type"],
                        "Comment": f"{col['description']:.{glue_comment_char_limit}}",
                    }
                )

            self.data = glue_schema
            self.logger.info("Data Product schema converted to csv glue table input")
        else:
            self.logger.error("schema not validated before attempted conversion")

        return self

    def _get_parent_data_product_metadata(self) -> Dict | None:
        data_product_metadata_path = DataProductConfig(
            name=self.data_product_name
        ).metadata_path(version=self.version)

        metadata = read_json_from_s3(data_product_metadata_path.uri)

        return metadata

    def detect_column_differences_in_new_version(self) -> dict:
        """
        Detects and returns what has changed comparing the latest saved version of
        schema with an updated version that has passed validation but not yet been
        converted to a glue table input (is available at self.data_pre_convert)
        """

        types_changed = []
        descriptions_changed = []
        changes = {}

        old_col_list = format_table_schema(self.latest_version_saved_data)["columns"]
        new_col_list = self.data_pre_convert["columns"]

        old_col_dict = {
            col["name"]: {"type": col["type"], "description": col["description"]}
            for col in old_col_list
        }
        new_col_dict = {
            col["name"]: {"type": col["type"], "description": col["description"]}
            for col in new_col_list
        }

        old_col_names = set(old_col_dict.keys())
        new_col_names = set(new_col_dict.keys())

        added_columns = list(new_col_names - old_col_names)
        removed_columns = list(old_col_names - new_col_names)

        # check each column in old schema against column in new schema for type or description
        # changes, if old column exists in new columns
        types_changed = [
            old_col
            for old_col in old_col_dict
            if new_col_dict.get(old_col) is not None
            and not old_col_dict[old_col]["type"] == new_col_dict[old_col]["type"]
        ]
        descriptions_changed = [
            old_col
            for old_col in old_col_dict
            if new_col_dict.get(old_col) is not None
            and not old_col_dict[old_col]["description"]
            == new_col_dict[old_col]["description"]
        ]

        changes["removed_columns"] = removed_columns if removed_columns else None
        changes["added_columns"] = added_columns if added_columns else None
        changes["types_changed"] = types_changed if types_changed else None
        changes["descriptions_changed"] = (
            descriptions_changed if descriptions_changed else None
        )

        return changes


class DataProductMetadata(BaseJsonSchema):
    """
    class to handle creation and updating of
    schema json files relating to data products as a whole
    """

    def __init__(
        self,
        data_product_name: str,
        logger: DataPlatformLogger,
        input_data: dict | None,
    ):
        latest_version_path = DataProductConfig(data_product_name).metadata_path()

        super().__init__(
            json_type=JsonSchemaName("metadata"),
            data_product_name=data_product_name,
            logger=logger,
            latest_version_path=latest_version_path,
            input_data=input_data,
        )

    def add_auto_generated_metadata(self):
        """adds key value pairs to metadata that are not given by a user."""
        raise NotImplementedError
