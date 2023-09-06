import json
import os
import traceback

import boto3
import botocore
from data_platform_logging import DataPlatformLogger
from dataengineeringutils3.s3 import get_filepaths_from_s3_folder, read_json_from_s3
from jsonschema import validate
from jsonschema.exceptions import ValidationError

s3_client = boto3.client("s3")


# These can be moved to separate module for all paths when work starts on that
def get_bucket_name() -> str:
    return os.environ["BUCKET_NAME"]


def get_data_product_metadata_path(data_product_name: str) -> str:
    metadata_s3_path = os.path.join(
        "s3://",
        get_bucket_name(),
        "metadata",
        data_product_name,
        "v1.0",
        "metadata.json",
    )
    return metadata_s3_path


def get_data_product_metadata_spec_path(version: str = "") -> str:
    # if version is empty we'll get the latest version
    if version == "":
        file_paths = get_filepaths_from_s3_folder(
            os.path.join("s3://", get_bucket_name(), "data_product_metadata_spec")
        )
        versions = list(
            {i for p in file_paths for i in p.split("/") if i.startswith("v")}
        )
        versions.sort()
        latest_version = versions[-1]
        spec_path = os.path.join(
            "s3://",
            get_bucket_name(),
            "data_product_metadata_spec",
            latest_version,
            "moj_data_product_metadata_spec.json",
        )
    else:
        spec_path = os.path.join(
            "s3://",
            get_bucket_name(),
            "data_product_metadata_spec",
            version,
            "moj_data_product_metadata_spec.json",
        )

    return spec_path


def split_bucket_and_key(path):
    bucket, key = path.replace("s3://", "").split("/", 1)
    return bucket, key


class DataProductMetadata:
    """
    class to handle creation and updating of
    metadata relating to a dataproduct
    """

    def __init__(self, data_product_name: str, logger: DataPlatformLogger):
        self.data_product_name = data_product_name
        self.logger = logger
        bucket, key = split_bucket_and_key(
            get_data_product_metadata_path(data_product_name)
        )
        self.metadata_bucket = bucket
        self.metadata_key = key
        self._check_if_metadata_exists()

    def _check_if_metadata_exists(self) -> object:
        # establish whether metadata for data product already exists
        try:
            # get head of object (if it exists)
            s3_client.head_object(Bucket=self.metadata_bucket, Key=self.metadata_key)
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "404":
                self.logger.info("No metadata exists for this data product")
                self.metadata_exists = False
            else:
                self.logger.error(f"Uknown error - {e}")
                raise Exception(f"Uknown error - {e}")
        else:
            self.logger.info(
                "version 1 of metadata already exists for this data product"
            )
            self.metadata_exists = True

        return self

    def validate(
        self,
        data_product_metadata: dict,
        metadata_schema_version: str = "",
    ) -> object:
        metadata_schema = read_json_from_s3(
            get_data_product_metadata_spec_path(metadata_schema_version)
        )
        try:
            validate(instance=data_product_metadata, schema=metadata_schema)
        except ValidationError:
            self.error_traceback = traceback.format_exc()
            self.logger.error(
                f"metadata has failed validation with error: {self.error_traceback}"
            )
            self.valid_metadata = False
        else:
            self.logger.info("metadata has passed validation")
            self.valid_metadata = True
            self.data_product_metadata = data_product_metadata
        return self

    def write_json_to_s3(self) -> None:
        if hasattr(self, "data_product_metadata") and self.valid_metadata:
            json_metadata = json.dumps(self.data_product_metadata)
            s3_client.put_object(
                Body=json_metadata,
                Bucket=self.metadata_bucket,
                Key=self.metadata_key,
                **{
                    "ACL": "bucket-owner-full-control",
                    "ServerSideEncryption": "AES256",
                },
            )
            self.logger.info("Data Product metadata written to s3")
        else:
            self.logger.error(
                "Metadata need to be validated before writing to s3, run the validate() class method"
            )
            raise ValidationError(
                "Metadata must be validated before being written to s3."
            )
