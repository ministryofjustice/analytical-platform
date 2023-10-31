import copy
import json
import logging
from typing import Any

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

test_schema: dict[str, Any] = {
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

input_data1 = copy.deepcopy(test_schema)
input_data1["columns"][0] = {
    "name": "col_1",
    "type": "int",
    "description": "ABCDEFGHIJKLMNOPQRSTUVWXY",
}
expected1 = {
    "test_table": {
        "columns": {
            "removed_columns": None,
            "added_columns": None,
            "types_changed": ["col_1"],
            "descriptions_changed": None,
        },
        "non_column_fields": None,
    }
}
input_data2 = copy.deepcopy(test_schema)
input_data2["columns"].pop(0)
expected2 = {
    "test_table": {
        "columns": {
            "removed_columns": ["col_1"],
            "added_columns": None,
            "types_changed": None,
            "descriptions_changed": None,
        },
        "non_column_fields": None,
    }
}
input_data3 = copy.deepcopy(test_schema)
input_data3["columns"][0] = {
    "name": "col_1",
    "type": "string",
    "description": "A",
}
input_data3["columns"].pop(1)
input_data3["tableDescription"] = "changed"
expected3 = {
    "test_table": {
        "columns": {
            "removed_columns": ["col_2"],
            "added_columns": None,
            "types_changed": ["col_1"],
            "descriptions_changed": ["col_1"],
        },
        "non_column_fields": ["tableDescription"],
    }
}

major_inputs = [
    (input_data1, expected1),
    (input_data2, expected2),
    (input_data3, expected3),
]

input_data4 = copy.deepcopy(test_schema)
input_data4["tableDescription"] = "changed"
expected4 = {
    "test_table": {
        "columns": {
            "removed_columns": None,
            "added_columns": None,
            "types_changed": None,
            "descriptions_changed": None,
        },
        "non_column_fields": ["tableDescription"],
    }
}

input_data5 = copy.deepcopy(test_schema)
input_data5["columns"].append(
    {"name": "col_5", "type": "smallint", "description": "JKJK"}
)
expected5 = {
    "test_table": {
        "columns": {
            "removed_columns": None,
            "added_columns": ["col_5"],
            "types_changed": None,
            "descriptions_changed": None,
        },
        "non_column_fields": None,
    }
}

input_data6 = copy.deepcopy(test_schema)
input_data6["columns"][0] = {
    "name": "col_1",
    "type": "bigint",
    "description": "A",
}
expected6 = {
    "test_table": {
        "columns": {
            "removed_columns": None,
            "added_columns": None,
            "types_changed": None,
            "descriptions_changed": ["col_1"],
        },
        "non_column_fields": None,
    }
}

input_data7 = copy.deepcopy(test_schema)
input_data7["columns"][0] = {
    "name": "col_1",
    "type": "bigint",
    "description": "A",
}
input_data7["columns"].append(
    {"name": "col_5", "type": "smallint", "description": "JKJK"}
)
input_data7["tableDescription"] = "changed"
expected7 = {
    "test_table": {
        "columns": {
            "removed_columns": None,
            "added_columns": ["col_5"],
            "types_changed": None,
            "descriptions_changed": ["col_1"],
        },
        "non_column_fields": ["tableDescription"],
    }
}

minor_inputs = [
    (input_data4, expected4),
    (input_data5, expected5),
    (input_data6, expected6),
    (input_data7, expected7),
]


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
        contents = self.s3_client.list_objects_v2(
            Bucket=self.bucket_name, Prefix=f"{test_metadata['name']}/{version}"
        )["Contents"]
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

    @pytest.mark.parametrize("input_data, expected", minor_inputs)
    def test_creates_minor_version_schema(self, s3_client, input_data, expected):
        s3_client.put_object(
            Body=json.dumps(test_glue_table_input),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )

        version_creator = VersionCreator(test_metadata["name"], logging.getLogger())

        version, changes = version_creator.update_schema(input_data, "test_table")

        assert version == "v1.1"
        assert changes == expected
        self.assert_has_keys(
            {
                "test_product/v1.1/metadata.json",
                "test_product/v1.1/test_table/schema.json",
            },
            "v1.1",
        )

    @pytest.mark.parametrize("input_data, expected", major_inputs)
    def test_creates_major_version_schema(self, s3_client, input_data, expected):
        s3_client.put_object(
            Body=json.dumps(test_glue_table_input),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )

        version_creator = VersionCreator(test_metadata["name"], logging.getLogger())

        version, changes = version_creator.update_schema(input_data, "test_table")

        assert version == "v2.0"
        assert changes == expected
        self.assert_has_keys(
            {
                "test_product/v2.0/metadata.json",
                "test_product/v2.0/test_table/schema.json",
            },
            "v2.0",
        )

    def test_unchanged_schema_as_input(self, s3_client):
        s3_client.put_object(
            Body=json.dumps(test_glue_table_input),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )
        input_data = copy.deepcopy(test_schema)

        version_creator = VersionCreator(test_metadata["name"], logging.getLogger())
        with pytest.raises(InvalidUpdate):
            version, changes = version_creator.update_schema(input_data, "test_table")

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
