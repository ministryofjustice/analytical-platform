"""
Functionality for creating major and minor version updates to a data product.
"""
from __future__ import annotations

from enum import Enum
from typing import NamedTuple

import boto3
from data_platform_logging import DataPlatformLogger, s3_security_opts
from data_platform_paths import DataProductConfig, delete_all_element_version_data_files
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


class VersionCreator:
    """
    Service to create new versions of a data product when metadata or schema are updated.
    """

    def __init__(self, data_product_name, logger: DataPlatformLogger):
        self.data_product_config = DataProductConfig(name=data_product_name)
        self.logger = logger

    def update_metadata_remove_schemas(self, schema_list: list[str]) -> str:
        """Handles removing schema(s) for a data product."""
        s3_client = boto3.client("s3")

        current_metadata = (
            DataProductMetadata(
                data_product_name=self.data_product_config.name,
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
            error = f"Invalid schemas found in schema_list: {schema_list}"
            self.logger.error(error)
            raise InvalidUpdate(error)

        self.logger.info(f"schemas to delete: {schema_list}")
        for schema in schema_list:
            # Delete the Glue table
            result = delete_glue_table(
                data_product_name=self.data_product_config.name,
                table_name=schema,
                logger=self.logger,
            )
            self.logger.info(str(result))

            # Delete a given elements raw and curated data for all versions of the data product
            delete_all_element_version_data_files(
                data_product_name=self.data_product_config.name, table_name=schema
            )

        current_metadata["schemas"] = [
            schema for schema in current_schemas if schema not in schema_list
        ]
        updated_metadata = DataProductMetadata(
            data_product_name=self.data_product_config.name,
            logger=self.logger,
            input_data=current_metadata,
        ).load()

        if not updated_metadata.valid:
            error = "updated metadata validation failed"
            self.logger.error(error)
            raise InvalidUpdate(error)

        latest_version = updated_metadata.version
        new_version = generate_next_version_string(
            latest_version, UpdateType.MajorUpdate
        )
        self.logger.info(f"new version: {new_version}")

        source_folder = f"{self.data_product_config.name}/{latest_version}/"
        # Copy files to the new version
        s3_copy_folder_to_new_folder(
            updated_metadata.write_bucket,
            source_folder,
            latest_version,
            new_version,
            self.logger,
        )
        # Remove schema files that we no longer require in this version
        for schema in schema_list:
            # Get the current version of the schema path
            schema_path = DataProductConfig(
                name=self.data_product_config.name
            ).schema_path(table_name=schema, version=new_version)
            # Delete the schema.json file for the table we have removed
            s3_client.delete_object(Bucket=schema_path.bucket, Key=schema_path.key)

        # Get the metadata path for the new version
        new_version_key = self.data_product_config.metadata_path(new_version).key
        # Overwite the copied metadata.json file with the updated parameters
        updated_metadata.write_json_to_s3(new_version_key)

        return new_version

    def update_metadata(self, input_data) -> str:
        """
        Create a new version with updated metadata.
        """
        metadata = DataProductMetadata(
            data_product_name=self.data_product_config.name,
            logger=self.logger,
            input_data=input_data,
        ).load()
        if not metadata.valid or not metadata.exists:
            raise InvalidUpdate()

        state = metadata_update_type(metadata)
        self.logger.info(f"Update type {state}")

        if state != UpdateType.MinorUpdate:
            raise InvalidUpdate(state)

        latest_version = metadata.version
        new_version = generate_next_version_string(latest_version, state)
        self._copy_from_previous_version(
            latest_version=latest_version, new_version=new_version
        )
        new_version_key = self.data_product_config.metadata_path(new_version).key
        metadata.write_json_to_s3(new_version_key)

        return new_version

    def update_schema(self, input_data: dict, table_name: str):
        """
        Create a new version with updated schema.
        """
        schema = DataProductSchema(
            data_product_name=self.data_product_config.name,
            table_name=table_name,
            input_data=input_data,
            logger=self.logger,
        ).load()

        if not schema.valid:
            raise InvalidUpdate()

        state, changes = schema_update_type(schema)
        self.logger.info(f"Update type {state}")
        if not state == UpdateType.Unchanged:
            self.logger.info(f"Changes to schema: {changes}")

            latest_version = schema.version
            new_version = generate_next_version_string(schema.version, state)
            self._copy_from_previous_version(
                latest_version=latest_version, new_version=new_version
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
        return UpdateType.Unchanged
    if changed_fields.difference(UPDATABLE_METADATA_FIELDS):
        return UpdateType.NotAllowed
    else:
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
        elif changed_fields.intersection(MINOR_UPDATE_SCHEMA_FIELDS):
            update_type = UpdateType.MinorUpdate

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
    Recurisvely copy a folder, replacing {latest_version} with {new_version}
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
