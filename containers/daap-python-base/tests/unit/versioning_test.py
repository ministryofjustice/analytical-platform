import json
import logging

import pytest
from versioning import InvalidUpdate, VersionCreator

test_metadata = {
    "name": "test_product",
    "description": "just testing the metadata json validation/registration",
    "domain": "MoJ",
    "dataProductOwner": "matthew.laverty@justice.gov.uk",
    "dataProductOwnerDisplayName": "matt laverty",
    "email": "matthew.laverty@justice.gov.uk",
    "status": "draft",
    "retentionPeriod": 3000,
    "dpiaRequired": False,
}

test_schema = {
    "tableDescription": "table has schema to pass test",
    "columns": [
        {
            "name": "col_1",
            "type": "bigint",
            "description": "ABCDEFGHIJKLMNOPQRSTUVWXY",
        },
        {"name": "col_2", "type": "tinyint", "description": "ABCDEFGHIJKL"},
        {
            "name": "col_3",
            "type": "int",
            "description": "ABCDEFGHIJKLMNOPQRSTUVWX",
        },
        {"name": "col_4", "type": "smallint", "description": "ABCDEFGHIJKLMN"},
    ],
}


class TestVersionCreator:
    @pytest.fixture(autouse=True)
    def setup(self, metadata_bucket, s3_client):
        self.s3_client = s3_client
        self.bucket_name = metadata_bucket
        s3_client.put_object(
            Body=json.dumps(test_metadata),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/metadata.json",
        )

    def assert_has_keys(self, keys):
        contents = self.s3_client.list_objects_v2(
            Bucket=self.bucket_name, Prefix=f"{test_metadata['name']}/v1.1"
        )["Contents"]
        actual = {i["Key"] for i in contents}

        assert actual == keys

    def test_creates_minor_version(
        self,
    ):
        input_data = dict(**test_metadata)
        input_data["description"] = "New description"

        version_creator = VersionCreator(test_metadata["name"], logging.getLogger())

        version = version_creator.update_metadata(input_data)

        assert version == "v1.1"
        self.assert_has_keys({"test_product/v1.1/metadata.json"})

    def test_copies_schemas(self, s3_client):
        s3_client.put_object(
            Body=json.dumps(test_schema),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )

        input_data = dict(**test_metadata)
        input_data["description"] = "New description"

        version_creator = VersionCreator(test_metadata["name"], logging.getLogger())

        version_creator.update_metadata(input_data)

        self.assert_has_keys(
            {
                "test_product/v1.1/metadata.json",
                "test_product/v1.1/test_table/schema.json",
            }
        )

    def test_cannot_update_name(self):
        input_data = dict(**test_metadata)
        input_data["name"] = "new name"

        version_creator = VersionCreator(test_metadata["name"], logging.getLogger())

        with pytest.raises(InvalidUpdate):
            version_creator.update_metadata(input_data)
