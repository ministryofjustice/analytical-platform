import copy
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

test_glue_table_input = {
    "DatabaseName": "test_product",
    "TableInput": {
        "Description": "table has schema to pass test",
        "Name": "test_table",
        "Owner": "matthew.laverty@justice.gov.uk",
        "Retention": 3000,
        "Parameters": {"classification": "csv", "skip.header.line.count": "1"},
        "PartitionKeys": [],
        "StorageDescriptor": {
            "BucketColumns": [],
            "Columns": [
                {
                    "Name": "col_1",
                    "Type": "bigint",
                    "Comment": "ABCDEFGHIJKLMNOPQRSTUVWXY",
                },
                {"Name": "col_2", "Type": "tinyint", "Comment": "ABCDEFGHIJKL"},
                {
                    "Name": "col_3",
                    "Type": "int",
                    "Comment": "ABCDEFGHIJKLMNOPQRSTUVWX",
                },
                {"Name": "col_4", "Type": "smallint", "Comment": "ABCDEFGHIJKLMN"},
            ],
            "Compressed": False,
            "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
            "Location": "",
            "NumberOfBuckets": -1,
            "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
            "Parameters": {},
            "SerdeInfo": {
                "Parameters": {"escape.delim": "\\", "field.delim": ","},
                "SerializationLibrary": "org.apache.hadoop.hive.serde2.OpenCSVSerde",
            },
            "SortColumns": [],
            "StoredAsSubDirectories": False,
        },
        "TableType": "EXTERNAL_TABLE",
    },
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

    def assert_has_keys(self, keys, version):
        contents = self.s3_client.list_objects_v2(Bucket=self.bucket_name, Prefix=f"{test_metadata['name']}/{version}")[
            "Contents"
        ]
        actual = {i["Key"] for i in contents}

        assert actual == keys

    def test_creates_minor_version_metadata(
        self,
    ):
        input_data = dict(**test_metadata)
        input_data["description"] = "New description"

        version_creator = VersionCreator(test_metadata["name"], logging.getLogger())

        version = version_creator.update_metadata(input_data)

        assert version == "v1.1"
        self.assert_has_keys({"test_product/v1.1/metadata.json"}, "v1.1")

    def test_creates_minor_version_schema(self, s3_client):
        s3_client.put_object(
            Body=json.dumps(test_glue_table_input),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )

        input_data = copy.deepcopy(test_schema)
        input_data["tableDescription"] = "table has schema to pass test and an extra column"
        input_data["columns"].append({"name": "col_5", "type": "smallint", "description": "JKJK"})

        version_creator = VersionCreator(test_metadata["name"], logging.getLogger())

        version, changes = version_creator.update_schema(input_data, "test_table")

        assert version == "v1.1"
        assert changes == {
            "test_table": {
                "columns": {
                    "removed_columns": None,
                    "added_columns": {"col_5"},
                    "types_changed": None,
                    "descriptions_changed": None,
                },
                "non_column_fields": ["tableDescription"],
            }
        }
        self.assert_has_keys({"test_product/v1.1/metadata.json", "test_product/v1.1/test_table/schema.json"}, "v1.1")

    def test_creates_major_version_schema(self, s3_client):
        s3_client.put_object(
            Body=json.dumps(test_glue_table_input),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )

        input_data = copy.deepcopy(test_schema)
        input_data["columns"].pop(0)

        version_creator = VersionCreator(test_metadata["name"], logging.getLogger())

        version, changes = version_creator.update_schema(input_data, "test_table")

        assert version == "v2.0"
        assert changes == {
            "test_table": {
                "columns": {
                    "removed_columns": {"col_1"},
                    "added_columns": None,
                    "types_changed": None,
                    "descriptions_changed": None,
                },
                "non_column_fields": None,
            }
        }
        self.assert_has_keys({"test_product/v2.0/metadata.json", "test_product/v2.0/test_table/schema.json"}, "v2.0")

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
            },
            "v1.1",
        )

    def test_cannot_update_name(self):
        input_data = dict(**test_metadata)
        input_data["name"] = "new name"

        version_creator = VersionCreator(test_metadata["name"], logging.getLogger())

        with pytest.raises(InvalidUpdate):
            version_creator.update_metadata(input_data)

    def test_cannot_update_product_that_does_not_exist(self):
        input_data = dict(**test_metadata)
        input_data["description"] = "New description"

        version_creator = VersionCreator("does_not_exist", logging.getLogger())

        with pytest.raises(InvalidUpdate):
            version_creator.update_metadata(input_data)
