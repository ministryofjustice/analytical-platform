import copy
import json
import logging
import os
from typing import Any
from unittest.mock import patch

import pytest
from botocore.exceptions import ClientError
from data_product_metadata import DataProductSchema
from versioning import InvalidUpdate, VersionManager

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

test_metadata_with_schemas = {
    "name": "test_product_with_schemas",
    "description": "just testing the metadata json validation/registration",
    "domain": "MoJ",
    "dataProductOwner": "matthew.laverty@justice.gov.uk",
    "dataProductOwnerDisplayName": "matt laverty",
    "email": "matthew.laverty@justice.gov.uk",
    "status": "draft",
    "retentionPeriod": 3000,
    "dpiaRequired": False,
    "schemas": ["schema0", "schema1", "schema2"],
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


class TestVersionManager:
    @pytest.fixture(autouse=True)
    def setup(self, metadata_bucket, s3_client, data_product_name):
        self.s3_client = s3_client
        self.bucket_name = metadata_bucket
        s3_client.put_object(
            Body=json.dumps(test_metadata),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/metadata.json",
        )
        s3_client.put_object(
            Body=json.dumps(test_metadata_with_schemas),
            Bucket=self.bucket_name,
            Key="test_product_with_schemas/v1.0/metadata.json",
        )

    def assert_has_keys(self, keys, version, data_product_name=test_metadata["name"]):
        contents = self.s3_client.list_objects_v2(
            Bucket=self.bucket_name, Prefix=f"{data_product_name}/{version}"
        )["Contents"]
        actual = {i["Key"] for i in contents}

        assert actual == keys

    def test_updates_minor_version_metadata(
        self,
    ):
        input_data = dict(**test_metadata)
        input_data["description"] = "New description"

        version_manager = VersionManager(test_metadata["name"], logging.getLogger())

        version = version_manager.update_metadata(input_data)

        assert version == "v1.1"
        self.assert_has_keys({"test_product/v1.1/metadata.json"}, "v1.1")

    @pytest.mark.parametrize("input_data, expected", minor_inputs)
    def test_updates_minor_version_schema(self, s3_client, input_data, expected):
        s3_client.put_object(
            Body=json.dumps(test_glue_table_input),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )

        version_manager = VersionManager(test_metadata["name"], logging.getLogger())

        version, changes = version_manager.update_schema(input_data, "test_table")

        assert version == "v1.1"
        assert changes == expected
        self.assert_has_keys(
            {
                "test_product/v1.1/metadata.json",
                "test_product/v1.1/test_table/schema.json",
            },
            "v1.1",
        )

    def test_create_schema_version_new(self, s3_client, table_name):
        data_product_name = test_metadata["name"]
        version_manager = VersionManager(data_product_name, logging.getLogger())
        schema = DataProductSchema(
            data_product_name=data_product_name,
            table_name=table_name,
            logger=logging.getLogger(),
            input_data=test_schema,
        )
        version = version_manager.create_schema(schema)

        assert version == "v1.0"
        self.assert_has_keys(
            {
                "test_product/v1.0/metadata.json",
                "test_product/v1.0/table-name/schema.json",
            },
            "v1.0",
            data_product_name,
        )

    def test_create_schema_version_exists_bump(self, table_name):
        data_product_name = test_metadata_with_schemas["name"]
        version_manager = VersionManager(data_product_name, logging.getLogger())

        schema = DataProductSchema(
            data_product_name="test_product_with_schemas",
            table_name=table_name,
            logger=logging.getLogger(),
            input_data=test_schema,
        )
        version = version_manager.create_schema(schema)

        assert version == "v1.1"
        self.assert_has_keys(
            {
                "test_product_with_schemas/v1.1/metadata.json",
                "test_product_with_schemas/v1.1/table-name/schema.json",
            },
            "v1.1",
            data_product_name,
        )

    @pytest.mark.parametrize("input_data, expected", major_inputs)
    def test_creates_major_version_schema(self, s3_client, input_data, expected):
        s3_client.put_object(
            Body=json.dumps(test_glue_table_input),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )

        version_manager = VersionManager(test_metadata["name"], logging.getLogger())

        version, changes = version_manager.update_schema(input_data, "test_table")

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

        version_manager = VersionManager(test_metadata["name"], logging.getLogger())
        with pytest.raises(InvalidUpdate):
            version, changes = version_manager.update_schema(input_data, "test_table")

    def test_copies_schemas(self, s3_client):
        s3_client.put_object(
            Body=json.dumps(test_schema),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )

        input_data = dict(**test_metadata)
        input_data["description"] = "New description"

        version_manager = VersionManager(test_metadata["name"], logging.getLogger())

        version_manager.update_metadata(input_data)

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

        version_manager = VersionManager(test_metadata["name"], logging.getLogger())

        with pytest.raises(InvalidUpdate):
            version_manager.update_metadata(input_data)

    def test_cannot_update_product_that_does_not_exist(self):
        input_data = dict(**test_metadata)
        input_data["description"] = "New description"

        version_manager = VersionManager("does_not_exist", logging.getLogger())

        with pytest.raises(InvalidUpdate):
            version_manager.update_metadata(input_data)


class TestUpdateMetadataRemoveSchema:
    @pytest.fixture(autouse=True)
    def setup(
        self,
        metadata_bucket,
        s3_client,
        glue_client,
        create_glue_database,
        data_product_name,
        data_product_versions,
    ):
        self.bucket_name = metadata_bucket
        for version in data_product_versions:
            s3_client.put_object(
                Body=json.dumps(test_metadata_with_schemas),
                Bucket=self.bucket_name,
                Key=f"{data_product_name}/{version}/metadata.json",
            )
        for i in range(3):
            for version in data_product_versions:
                s3_client.put_object(
                    Body=json.dumps(test_schema),
                    Bucket=self.bucket_name,
                    Key=f"{data_product_name}/{version}/schema{i}/schema.json",
                )
        glue_client.create_table(
            DatabaseName=data_product_name, TableInput={"Name": "schema0"}
        )

    def test_success(
        self, s3_client, create_raw_and_curated_data, data_product_name, glue_client
    ):
        version_manager = VersionManager(data_product_name, logging.getLogger())
        schema_list = ["schema0"]
        with patch("glue_utils.glue_client", glue_client):
            version_manager.update_metadata_remove_schemas(schema_list=schema_list)
            schema_prefix = f"{data_product_name}/v2.0/metadata.json"
            response = s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=schema_prefix,
            )
        assert response.get("KeyCount") == 1

    def test_invalid_schemas(self, data_product_name):
        version_manager = VersionManager(data_product_name, logging.getLogger())
        schema_list = ["schema3", "schema4"]

        with pytest.raises(InvalidUpdate) as exc:
            version_manager.update_metadata_remove_schemas(schema_list=schema_list)
        assert (
            str(exc.value)
            == "Invalid schemas found in schema_list: ['schema3', 'schema4']"
        )

    def test_glue_table_not_found(
        self,
        s3_client,
        create_raw_and_curated_data,
        data_product_name,
        glue_client,
        table_name,
    ):
        version_manager = VersionManager(data_product_name, logging.getLogger())
        schema_list = ["schema0", "schema1"]
        with patch("glue_utils.glue_client", glue_client):
            with pytest.raises(ValueError) as exc:
                version_manager.update_metadata_remove_schemas(schema_list=schema_list)
                assert (
                    str(exc.value)
                    == f"Could not locate glue table '{table_name}' in database '{data_product_name}'"
                )

    def test_schema_glue_table_deleted(
        self, s3_client, create_raw_and_curated_data, data_product_name, glue_client
    ):
        version_manager = VersionManager(data_product_name, logging.getLogger())
        schema_list = ["schema0"]
        with patch("glue_utils.glue_client", glue_client):
            table = glue_client.get_table(
                DatabaseName=data_product_name, Name=f"{schema_list[0]}"
            )
            assert table["ResponseMetadata"]["HTTPStatusCode"] == 200
            assert table["Table"]["Name"] == schema_list[0]

            with pytest.raises(ClientError) as exc:
                # Call the handler
                version_manager.update_metadata_remove_schemas(schema_list=schema_list)

                table = glue_client.get_table(
                    DatabaseName=data_product_name, Name=f"{schema_list[0]})"
                )
            assert exc.value.response["Error"]["Code"] == "EntityNotFoundException"
            assert f"{schema_list[0]}" in exc.value.response["Error"]["Message"]

    def test_data_files_deleted(
        self,
        s3_client,
        create_raw_and_curated_data,
        data_product_name,
        glue_client,
        data_product_major_versions,
    ):
        version_manager = VersionManager(data_product_name, logging.getLogger())
        schema_list = ["schema0"]
        with patch("glue_utils.glue_client", glue_client):
            # Validate we have the required number of files
            for version in data_product_major_versions:
                curated_prefix = f"curated/{data_product_name}/{version}/schema0/"
                response = s3_client.list_objects_v2(
                    Bucket=os.getenv("CURATED_DATA_BUCKET"),
                    Prefix=curated_prefix,
                )
                assert response.get("KeyCount") == 10

                raw_prefix = f"raw/{data_product_name}/{version}/schema0/"
                response = s3_client.list_objects_v2(
                    Bucket=os.getenv("RAW_DATA_BUCKET"),
                    Prefix=raw_prefix,
                )
                assert response.get("KeyCount") == 10

            # Call the handler
            version_manager.update_metadata_remove_schemas(schema_list=schema_list)

            # Validate files are deleted
            for version in data_product_major_versions:
                curated_prefix = f"curated/{data_product_name}/{version}/schema0/"
                response = s3_client.list_objects_v2(
                    Bucket=os.getenv("CURATED_DATA_BUCKET"),
                    Prefix=curated_prefix,
                )
                assert response.get("KeyCount") == 0

                raw_prefix = f"raw/{data_product_name}/{version}/schema0/"
                response = s3_client.list_objects_v2(
                    Bucket=os.getenv("RAW_DATA_BUCKET"),
                    Prefix=raw_prefix,
                )
                assert response.get("KeyCount") == 0

    def test_deleted_schema_files_removed_from_new_version(
        self,
        s3_client,
        create_raw_and_curated_data,
        data_product_name,
        glue_client,
        data_product_versions,
    ):
        version_manager = VersionManager(data_product_name, logging.getLogger())
        schema_list = ["schema0"]

        with patch("glue_utils.glue_client", glue_client):
            # Call the handler
            version_manager.update_metadata_remove_schemas(schema_list=schema_list)
            schema_prefix = f"{data_product_name}/v3.0/{schema_list[0]}/schema.json"
            response = s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=schema_prefix,
            )
            assert response.get("KeyCount") == 0

    def test_validate_other_schemas_are_upversioned(
        self,
        s3_client,
        create_raw_and_curated_data,
        data_product_name,
        glue_client,
        data_product_versions,
    ):
        version_manager = VersionManager(data_product_name, logging.getLogger())
        schema_list = ["schema0"]

        with patch("glue_utils.glue_client", glue_client):
            # Call the handler
            version_manager.update_metadata_remove_schemas(schema_list=schema_list)
            for i in range(1, 3):
                schema_prefix = f"{data_product_name}/v2.0/schema{i}/schema.json"
                response = s3_client.list_objects_v2(
                    Bucket=self.bucket_name,
                    Prefix=schema_prefix,
                )
                assert response.get("KeyCount") == 1


class TestRemoveAllVersions:
    @pytest.fixture(autouse=True)
    def setup(
        self,
        metadata_bucket,
        s3_client,
        glue_client,
        data_product_name,
        data_product_versions,
    ):
        self.bucket_name = metadata_bucket
        for version in data_product_versions:
            s3_client.put_object(
                Body=json.dumps(test_metadata_with_schemas),
                Bucket=self.bucket_name,
                Key=f"{data_product_name}/{version}/metadata.json",
            )
        for i in range(3):
            for version in data_product_versions:
                s3_client.put_object(
                    Body=json.dumps(test_schema),
                    Bucket=self.bucket_name,
                    Key=f"{data_product_name}/{version}/schema{i}/schema.json",
                )

    def test_success(
        self,
        s3_client,
        create_glue_tables,
        create_raw_and_curated_data,
        data_product_name,
        glue_client,
    ):
        # Assert we have the correct number of database tables created
        tables = glue_client.get_tables(DatabaseName=data_product_name)
        assert len(tables["TableList"]) == 3

        # Assert we have the correct number of metadata files to begin with
        prefix = f"{data_product_name}/"
        response = s3_client.list_objects_v2(
            Bucket=self.bucket_name,
            Prefix=prefix,
        )
        assert response.get("KeyCount") == 16

        # Assert we have the correct number of raw files to begin with
        prefix = f"raw/{data_product_name}/"
        response = s3_client.list_objects_v2(
            Bucket=os.getenv("RAW_DATA_BUCKET"),
            Prefix=prefix,
        )
        assert response.get("KeyCount") == 20

        # Assert we have the correct number of curated files to begin with
        prefix = f"curated/{data_product_name}/"
        response = s3_client.list_objects_v2(
            Bucket=os.getenv("CURATED_DATA_BUCKET"),
            Prefix=prefix,
        )
        assert response.get("KeyCount") == 20

        #######################################################################
        version_manager = VersionManager(data_product_name, logging.getLogger())

        with patch("glue_utils.glue_client", glue_client):
            # Call the handler
            version_manager.remove_all_versions_of_data_product()

            # Assert that all metadata files have been deleted
            prefix = f"{data_product_name}/"
            response = s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=prefix,
            )
            assert response.get("KeyCount") == 0

            # Assert that raw files have been deleted
            prefix = f"raw/{data_product_name}/"
            response = s3_client.list_objects_v2(
                Bucket=os.getenv("RAW_DATA_BUCKET"),
                Prefix=prefix,
            )
            assert response.get("KeyCount") == 0

            # Assert that curated files have been deleted
            prefix = f"curated/{data_product_name}/"
            response = s3_client.list_objects_v2(
                Bucket=os.getenv("CURATED_DATA_BUCKET"),
                Prefix=prefix,
            )
            assert response.get("KeyCount") == 0

            with pytest.raises(glue_client.exceptions.EntityNotFoundException) as exc:
                glue_client.get_database(Name=data_product_name)
            assert (
                exc.value.response["Error"]["Message"]
                == f"Database {data_product_name} not found."
            )
            assert exc.value.response["Error"]["Code"] == "EntityNotFoundException"

    def test_glue_table_does_not_exist(
        self,
        s3_client,
        create_glue_tables,
        create_raw_and_curated_data,
        data_product_name,
        glue_client,
    ):
        version_manager = VersionManager("fake_data_product_name", logging.getLogger())
        with pytest.raises(ValueError) as exc:
            # Call the handler
            version_manager.remove_all_versions_of_data_product()
        assert (
            str(exc.value) == "Could not locate glue database 'fake_data_product_name'"
        )
