"""
Functionality for creating major and minor version updates to a data product.
"""
from __future__ import annotations

from enum import Enum
from typing import NamedTuple

import boto3
from data_platform_logging import DataPlatformLogger, s3_security_opts
from data_platform_paths import (
    DataProductConfig,
    DataProductElement,
    generate_all_element_version_prefixes,
)
from data_product_metadata import DataProductMetadata, DataProductSchema
from glue_utils import delete_glue_table


class Version(NamedTuple):
    """
    Helper object for manipulating version strings.
    """

    major: int
    minor: int

    def __str__(self):
        return f"v{self.major}.{self.minor}"

    @staticmethod
    def parse(version_str) -> Version:
        major, minor = [int(i) for i in version_str.lstrip("v").split(".")]
        return Version(major, minor)

    def increment_major(self) -> Version:
        return Version(self.major + 1, 0)

    def increment_minor(self) -> Version:
        return Version(self.major, self.minor + 1)


UPDATABLE_METADATA_FIELDS = {
    "description",
    "email",
    "dataProductOwner",
    "dataProductOwnerDisplayName",
    "domain",
    "status",
    "dpiaRequired",
    "retentionPeriod",
    "dataProductMaintainer",
    "dataProductMaintainerDisplayName",
    "tags",
}

MINOR_UPDATE_SCHEMA_FIELDS = {"tableDescription"}


class UpdateType(Enum):
    """
    Whether a schema or data product update represents a major or minor update to the data product.

    Minor updates are those which are backwards compatable, e.g. adding a new table.

    Major updates are those which may require data consumers to update their code,
    e.g. if tables or fields are removed.
    """

    Unchanged = 0
    MinorUpdate = 1
    MajorUpdate = 2
    NotAllowed = 3


class InvalidUpdate(Exception):
    """
    Exception thrown when an update cannot be applied to a data product or schema
    """


class VersionManager:
    """
    Service to create new versions of a data product when metadata or schema are updated.
    """

    def __init__(self, data_product_name, logger: DataPlatformLogger):
        self.data_product_config = DataProductConfig(name=data_product_name)
        self.latest_version = self.data_product_config.latest_version
        self.logger = logger

    def update_metadata_remove_schemas(self, schema_list: list[str]) -> str:
        """Handles removing schema(s) for a data product."""
        s3_client = boto3.client("s3")
        # remove any list duplicates and preserve list order
        schema_list = list({k: None for k in schema_list}.keys())

        data_product_name = self.data_product_config.name

        current_metadata = (
            DataProductMetadata(
                data_product_name=data_product_name,
                logger=self.logger,
                input_data=None,
            )
            .load()
            .latest_version_saved_data
        )
        current_schemas = current_metadata.get("schemas", [])
        self.logger.info(f"Current schemas: {current_schemas}")

        valid_schemas_to_delete = all(
            schema in current_schemas for schema in schema_list
        )
        if not valid_schemas_to_delete:
            schemas_not_in_current = list(set(schema_list).difference(current_schemas))
            error = f"Invalid schemas found in schema_list: {sorted(schemas_not_in_current)}"
            self.logger.error(error)
            raise InvalidUpdate(error)

        self.logger.info(f"schemas to delete: {schema_list}")
        for schema_name in schema_list:
            # Delete the Glue table
            result = delete_glue_table(
                data_product_name=data_product_name,
                table_name=schema_name,
                logger=self.logger,
            )
            self.logger.info(str(result))

            # Delete a given elements raw and curated data for all versions of the data product
            delete_all_element_version_data_files(
                data_product_name=data_product_name, table_name=schema_name
            )

        current_metadata["schemas"] = [
            schema for schema in current_schemas if schema not in schema_list
        ]
        updated_metadata = DataProductMetadata(
            data_product_name=data_product_name,
            logger=self.logger,
            input_data=current_metadata,
        ).load()

        if not updated_metadata.valid:
            error = "updated metadata validation failed"
            self.logger.error(error)
            raise InvalidUpdate(error)

        new_version = generate_next_version_string(
            self.latest_version, UpdateType.MajorUpdate
        )
        self.logger.info(f"new version: {new_version}")

        # Copy files to the new version
        self._copy_from_previous_version(
            latest_version=self.latest_version, new_version=new_version
        )

        # Remove schema files that we no longer require in this version
        for schema in schema_list:
            # Get the current version of the schema path
            schema_path = DataProductConfig(name=data_product_name).schema_path(
                table_name=schema, version=new_version
            )
            # Delete the schema.json file for the table we have removed
            s3_client.delete_object(Bucket=schema_path.bucket, Key=schema_path.key)

        # Get the metadata path for the new version
        new_version_key = self.data_product_config.metadata_path(new_version).key
        # Overwite the copied metadata.json file with the updated parameters
        updated_metadata.write_json_to_s3(new_version_key)

        return new_version

    def _minor_version_bump(self, metadata: DataProductMetadata) -> str:
        """Increment a Data Product by a major version, doing the following:
            - increment version number
            - copy all metadata from the previous version (metadata.json, schema.json)
            - overwrite copied metadata.json with new version of metadata

        Args:
            metadata (DataProductMetadata): validated metadata

        Returns:
            str: new version number
        """
        new_version = generate_next_version_string(
            self.latest_version, UpdateType.MinorUpdate
        )
        self._copy_from_previous_version(
            latest_version=self.latest_version, new_version=new_version
        )
        new_version_key = self.data_product_config.metadata_path(new_version).key
        metadata.write_json_to_s3(new_version_key)

        return new_version

    def _verify_input_metadata(self, input_data: dict) -> DataProductMetadata:
        """Load and verify input Data Product metadata, raising errors if metadata is
        missing, invalid, or if there are changes to fields that cannot be altered
        between versions.

        Args:
            input_data (dict): input metadata in a format ready for loading into a
            DataProductMetadata object.

        Raises:
            InvalidUpdate: raised if metadata is missing, invalid, or if there are
            changes to fields that cannot be altered between versions

        Returns:
            DataProductMetadata: verified metadata object with current metadata in
            metadata.data and previous metadata in metadata.latest_version_saved_data
        """
        metadata = DataProductMetadata(
            data_product_name=self.data_product_config.name,
            logger=self.logger,
            input_data=input_data,
        ).load()

        if not metadata.valid or not metadata.exists:
            msg = "invalid metadata passed"
            raise InvalidUpdate(msg)

        changed_fields = metadata.changed_fields()
        if changed_fields.difference(UPDATABLE_METADATA_FIELDS):
            changed_fields = list(changed_fields)
            num_fields = len(changed_fields)
            msg = f"Non-updatable metadata field{('s'[:num_fields!=1])} changed:"
            for f in changed_fields:
                msg += f"{f}: {metadata.latest_version_saved_data[f]} -> {metadata.data[f]}; "
            self.logger.error(msg)
            raise InvalidUpdate(msg)

        return metadata

    def _verify_input_schema(
        self, input_data: dict, table_name: str
    ) -> DataProductSchema:
        """Load and verify input Data Product schema, raising errors if schema is
        missing, invalid, or if there is no associated parent Data Product.

        Args:
            input_data (dict): input schema in a format ready for loading into a
            DataProductSchema object.

        Raises:
            InvalidUpdate: raised if schema is missing, invalid, or if there is no
            associated parent Data Product

        Returns:
            DataProductSchema: verified schema object
        """
        schema = DataProductSchema(
            data_product_name=self.data_product_config.name,
            table_name=table_name,
            logger=self.logger,
            input_data=input_data,
        ).load()

        if not schema.valid:
            error_message = (
                f"schema for {table_name} has failed validation with the following error: "
                f"{schema.error_traceback}"
            )
            raise InvalidUpdate(error_message)

        if not schema.has_registered_data_product:
            error_message = (
                f"Schema for {table_name} has no registered metadata for the data "
                "product it belongs to. Please first register the data product "
                "metadata using the POST method of the /data-product/register endpoint."
            )
            raise InvalidUpdate(error_message)

        return schema

    def update_metadata(self, input_data) -> str:
        """
        Create a new version with updated metadata.
        """
        metadata = self._verify_input_metadata(input_data)

        state = metadata_update_type(metadata)
        self.logger.info(f"Update type {state}")

        if state != UpdateType.MinorUpdate:
            raise InvalidUpdate(state)

        new_version = self._minor_version_bump(metadata)

        return new_version

    def update_schema(self, input_data: dict, table_name: str) -> tuple[str, dict]:
        """
        Create a new version with updated schema.
        """
        schema = self._verify_input_schema(input_data=input_data, table_name=table_name)

        state, changes = schema_update_type(schema)
        self.logger.info(f"Update type {state}")
        if not state == UpdateType.Unchanged:
            self.logger.info(f"Changes to schema: {changes}")

            new_version = generate_next_version_string(schema.version, state)
            self._copy_from_previous_version(
                latest_version=self.latest_version, new_version=new_version
            )
            new_version_key = (
                DataProductConfig(schema.data_product_name)
                .schema_path(table_name, new_version)
                .key
            )
            schema.convert_schema_to_glue_table_input_csv()
            schema.write_json_to_s3(new_version_key)
            return new_version, changes
        else:
            raise InvalidUpdate()

    def create_schema(
        self, input_data: dict, table_name: str
    ) -> tuple[str, DataProductSchema]:
        """
        Generate a version number for a new schema. Returns "v1.0" if this is the first
        schema associated with that Data Product, otherwise returns a version number
        after a minor version bump.
        """
        schema = self._verify_input_schema(input_data=input_data, table_name=table_name)

        if schema.exists:
            error_message = (
                f"v1 of this schema for table {table_name} already exists. You can upversion this schema if "
                "there are changes from v1 using the PUT method of this endpoint. Or if this is a different "
                "table then please choose a different name for it."
            )
            raise InvalidUpdate(error_message)

        data_product_name = self.data_product_config.name
        metadata_dict = schema.parent_data_product_metadata

        metadata = self._verify_input_metadata(metadata_dict)
        schema.convert_schema_to_glue_table_input_csv()

        if (
            self.latest_version == "v1.0"
            and not schema.parent_product_has_registered_schema
        ):
            self.logger.info(
                f"No existing schemas are associated with {data_product_name}; "
                f"setting version to 'v1.0' for {schema.table_name}"
            )

            metadata.write_json_to_s3(metadata.latest_version_key)

            new_version = "v1.0"
        else:
            new_version = self._minor_version_bump(metadata)

        schema.write_json_to_s3(
            DataProductConfig(data_product_name)
            .schema_path(schema.table_name, new_version)
            .key
        )

        return new_version, schema

    def _copy_from_previous_version(self, latest_version, new_version):
        bucket, source_folder = self.data_product_config.metadata_path(
            latest_version
        ).parent

        s3_copy_folder_to_new_folder(
            bucket=bucket,
            source_folder=source_folder,
            latest_version=latest_version,
            new_version=new_version,
            logger=self.logger,
        )


def metadata_update_type(data_product_metadata: DataProductMetadata) -> UpdateType:
    """
    Figure out whether changes to the metadata represent a valid update
    """
    if not data_product_metadata.exists or not data_product_metadata.valid:
        return UpdateType.NotAllowed

    changed_fields = data_product_metadata.changed_fields()
    if not changed_fields:
        # NOTE: this does not capture all types of updates (e.g. changes to a column
        # data type inside an existing schema)
        return UpdateType.Unchanged
    if changed_fields.difference(UPDATABLE_METADATA_FIELDS):
        return UpdateType.NotAllowed
    else:
        # NOTE: this does not capture all types of updates (e.g. removal of schema ->
        # MajorUpdate)
        return UpdateType.MinorUpdate


def schema_update_type(
    data_product_schema: DataProductSchema,
) -> tuple[UpdateType, dict]:
    """
    Figure out whether changes to the input data represent a major or minor schema update
    and return the changes as a dict, e.g.
        {table_name: {columns:{...}, non_column_fields: {...}}}
    """
    if not data_product_schema.exists or not data_product_schema.valid:
        return UpdateType.NotAllowed, {}

    changed_fields = data_product_schema.changed_fields()

    if "columns" in changed_fields:
        column_changes = data_product_schema.detect_column_differences_in_new_version()

        if any([column_changes["removed_columns"], column_changes["types_changed"]]):
            update_type = UpdateType.MajorUpdate
        elif any(
            [column_changes["added_columns"], column_changes["descriptions_changed"]]
        ):
            update_type = UpdateType.MinorUpdate
        elif not any(
            [
                column_changes["removed_columns"],
                column_changes["types_changed"],
                column_changes["added_columns"],
                column_changes["descriptions_changed"],
            ]
        ):
            update_type = UpdateType.Unchanged
    else:
        column_changes = {
            "removed_columns": None,
            "added_columns": None,
            "types_changed": None,
            "descriptions_changed": None,
        }
        if not changed_fields:
            update_type = UpdateType.Unchanged
        elif changed_fields.intersection(MINOR_UPDATE_SCHEMA_FIELDS) == changed_fields:
            update_type = UpdateType.MinorUpdate
        else:
            update_type = UpdateType.MajorUpdate

    # could be returned and used to form notification of change to consumers of data when the
    # notification process is developed
    if not update_type == UpdateType.Unchanged:
        if "columns" in changed_fields:
            changed_fields.remove("columns")
        non_column_changed_fields = (
            [field for field in changed_fields] if changed_fields else None
        )
        all_schema_changes = {
            data_product_schema.table_name: {
                "columns": column_changes,
                "non_column_fields": non_column_changed_fields,
            }
        }
    else:
        all_schema_changes = {
            data_product_schema.table_name: {
                "columns": column_changes,
                "non_column_fields": None,
            }
        }

    return update_type, all_schema_changes


def s3_copy_folder_to_new_folder(
    bucket, source_folder, latest_version, new_version, logger
):
    """
    Recursively copy a folder, replacing {latest_version} with {new_version}
    """
    s3_client = boto3.client("s3")
    paginator = s3_client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(
        Bucket=bucket,
        Prefix=source_folder,
    )
    keys_to_copy = []
    try:
        for page in page_iterator:
            keys_to_copy += [item["Key"] for item in page["Contents"]]
    except KeyError as e:
        logger.error(f"metadata for folder is empty but shouldn't be: {e}")
    for key in keys_to_copy:
        copy_source = {"Bucket": bucket, "Key": key}
        destination_key = key.replace(latest_version, new_version)
        s3_client.copy(
            CopySource=copy_source,
            Bucket=bucket,
            Key=destination_key,
            ExtraArgs=s3_security_opts,
        )


def generate_next_version_string(
    version: str, update_type: UpdateType = UpdateType.MinorUpdate
) -> str:
    """
    Generate the next version
    """
    current_version = Version.parse(version)
    if update_type == UpdateType.MajorUpdate:
        return str(current_version.increment_major())
    elif update_type == UpdateType.MinorUpdate:
        return str(current_version.increment_minor())
    else:
        return version


def delete_all_element_version_data_files(data_product_name: str, table_name: str):
    """Deletes raw and curated data for all element versions"""
    # Proceed to delete the raw data
    element = DataProductElement.load(
        element_name=table_name, data_product_name=data_product_name
    )
    raw_prefixes = generate_all_element_version_prefixes(
        "raw", data_product_name, table_name
    )
    curated_prefixes = generate_all_element_version_prefixes(
        "curated", data_product_name, table_name
    )

    s3_recursive_delete(element.data_product.raw_data_bucket, raw_prefixes)
    s3_recursive_delete(element.data_product.curated_data_bucket, curated_prefixes)


def s3_recursive_delete(bucket_name: str, prefixes: list[str]) -> None:
    """Delete all files from a prefix in s3"""
    s3_resource = boto3.resource("s3")
    bucket = s3_resource.Bucket(bucket_name)
    for prefix in prefixes:
        bucket.objects.filter(Prefix=prefix).delete()
