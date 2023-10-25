"""
Functionality for creating major and minor version updates to a data product.
"""
from __future__ import annotations

from enum import Enum
from typing import NamedTuple

import boto3
from data_platform_logging import DataPlatformLogger, s3_security_opts
from data_platform_paths import DataProductConfig
from data_product_metadata import DataProductMetadata

s3_client = boto3.client("s3")


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
        return Version(self.major + 1, self.minor)

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

    def update_metadata(self, input_data) -> str:
        """
        Create a new version with updated metadata.
        """
        metadata = DataProductMetadata(
            data_product_name=self.data_product_config.name,
            logger=self.logger,
            input_data=input_data,
        ).load()
        if not metadata.valid:
            raise InvalidUpdate()

        state = metadata_update_type(metadata)
        self.logger.info(f"Update type {state}")

        if state != UpdateType.MinorUpdate:
            raise InvalidUpdate(state)

        latest_version = metadata.version
        new_version = str(Version.parse(latest_version).increment_minor())
        self._copy_from_previous_version(
            latest_version=latest_version, new_version=new_version
        )
        latest_version_key = self.data_product_config.metadata_path(new_version).key
        metadata.write_json_to_s3(latest_version_key)

        return new_version

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


def metadata_update_type(data_product_metadata) -> UpdateType:
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


def s3_copy_folder_to_new_folder(
    bucket, source_folder, latest_version, new_version, logger
):
    """
    Recurisvely copy a folder, replacing {latest_version} with {new_version}
    """
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
