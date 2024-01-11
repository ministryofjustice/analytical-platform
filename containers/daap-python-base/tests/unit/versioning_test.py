import copy
import json
import logging
import os
from typing import Any
from unittest.mock import patch

import pytest
from glue_and_athena_utils import database_exists, table_exists
from versioning import InvalidUpdate, VersionManager

logger = logging.getLogger()

test_metadata_no_schema = {
    "name": "test_product0",
    "description": "just testing the metadata json validation/registration",
    "domain": "MoJ",
    "dataProductOwner": "matthew.laverty@justice.gov.uk",
    "dataProductOwnerDisplayName": "matt laverty",
    "email": "matthew.laverty@justice.gov.uk",
    "status": "draft",
    "retentionPeriod": 3000,
    "dpiaRequired": False,
}

test_metadata = copy.deepcopy(test_metadata_no_schema)
test_metadata.update({"name": "test_product", "schemas": ["test_table"]})

test_metadata_with_schemas = copy.deepcopy(test_metadata_no_schema)
test_metadata_with_schemas.update(
    {
        "name": "test_product_with_schemas",
        "schemas": ["schema0", "schema1", "schema2"],
    }
)

test_metadata_with_opt_keys = copy.deepcopy(test_metadata_no_schema)
test_metadata_with_opt_keys.update(
    {
        "name": "test_product_with_opt_keys",
        "dpiaLocation": "s3://dpias/test",
    }
)

test_metadatas = [
    test_metadata,
    test_metadata_with_schemas,
    test_metadata_with_opt_keys,
    test_metadata_no_schema,
]

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
        "Name": "schema0",
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
input_data2["columns"][0] = {
    "name": "col_2",
    "type": "string",
    "description": "ABCDEFGHIJKL",
}
expected2 = {
    "test_table": {
        "columns": {
            "removed_columns": ["col_1"],
            "added_columns": None,
            "types_changed": ["col_2"],
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


class TestTableWithNoGlueDatabase:
    """
    Test that the operation doesn't error if a glue database does not exist already.
    Currently the creation of this database is delayed until the first data upload.
    So if this hasn't happened, we should skip any data copying that takes place as part of
    the versioning.
    """

    @pytest.fixture(autouse=True)
    def setup(
        self,
        metadata_bucket,
        s3_client,
        data_product_name,
        data_product_versions,
    ):
        self.s3_client = s3_client
        self.bucket_name = metadata_bucket
        self.data_product_name = data_product_name
        self.latest_major_version = "v2"
        self.new_major_version = "v3"

        for version in data_product_versions:
            s3_client.put_object(
                Body=json.dumps(
                    {
                        "name": "test_product0",
                        "description": "just testing the metadata json validation/registration",
                        "domain": "MoJ",
                        "dataProductOwner": "matthew.laverty@justice.gov.uk",
                        "dataProductOwnerDisplayName": "matt laverty",
                        "email": "matthew.laverty@justice.gov.uk",
                        "status": "draft",
                        "retentionPeriod": 3000,
                        "dpiaRequired": False,
                        "schemas": ["schema"],
                    }
                ),
                Bucket=self.bucket_name,
                Key=f"{data_product_name}/{version}/metadata.json",
            )

            s3_client.put_object(
                Body=json.dumps(test_schema),
                Bucket=self.bucket_name,
                Key=f"{data_product_name}/{version}/schema/schema.json",
            )

    @pytest.fixture(autouse=True)
    def setup_subject(self, glue_client, data_product_name):
        with patch("glue_and_athena_utils.glue_client", glue_client):
            self.version_manager = VersionManager(data_product_name, logger)
            yield

    def test_can_delete_schema(self):
        schema_list = ["schema"]
        self.version_manager.update_metadata_remove_schemas(schema_list=schema_list)


class TestVersionManager:
    @pytest.fixture(autouse=True)
    def setup(self, metadata_bucket, s3_client, data_product_name):
        self.s3_client = s3_client
        self.bucket_name = metadata_bucket

        for metadata in test_metadatas:
            s3_client.put_object(
                Body=json.dumps(metadata),
                Bucket=self.bucket_name,
                Key=f"{metadata['name']}/v1.0/metadata.json",
            )

    def assert_has_keys(self, keys, version, data_product_name=test_metadata["name"]):
        contents = self.s3_client.list_objects_v2(
            Bucket=self.bucket_name, Prefix=f"{data_product_name}/{version}"
        )["Contents"]
        actual = {
            i["Key"] for i in contents if i["Key"].startswith(f"{data_product_name}/")
        }

        assert actual == keys

    @pytest.mark.parametrize(
        "input_metadata",
        [test_metadata, test_metadata_with_schemas, test_metadata_with_opt_keys],
    )
    def test_updates_minor_version_metadata(self, input_metadata):
        input_data = dict(**input_metadata)
        input_data["description"] = "New description"

        version_manager = VersionManager(input_metadata["name"], logging.getLogger())

        version = version_manager.update_metadata(input_data)

        assert version == "v1.1"
        self.assert_has_keys(
            {f"{input_metadata['name']}/v1.1/metadata.json"},
            "v1.1",
            data_product_name=input_metadata["name"],
        )

    @pytest.mark.parametrize("input_data, expected", minor_inputs)
    def test_updates_minor_version_schema(self, s3_client, input_data, expected):
        s3_client.put_object(
            Body=json.dumps(test_glue_table_input),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )

        version_manager = VersionManager(test_metadata["name"], logging.getLogger())

        version, changes, copy_response = version_manager.update_schema(
            input_data, "test_table"
        )

        assert version == "v1.1"
        assert changes == expected
        assert copy_response is None
        self.assert_has_keys(
            {
                "test_product/v1.1/metadata.json",
                "test_product/v1.1/test_table/schema.json",
            },
            "v1.1",
        )

    def test_create_schema_version_new(self, s3_client, table_name):
        data_product_name = test_metadata_no_schema["name"]
        version_manager = VersionManager(data_product_name, logging.getLogger())

        version, _ = version_manager.create_schema(
            table_name=table_name, input_data=test_schema
        )

        assert version == "v1.0"
        self.assert_has_keys(
            {
                "test_product0/v1.0/metadata.json",
                "test_product0/v1.0/table-name/schema.json",
            },
            "v1.0",
            data_product_name,
        )

    def test_create_schema_version_exists_bump(self, table_name):
        data_product_name = test_metadata_with_schemas["name"]
        version_manager = VersionManager(data_product_name, logging.getLogger())

        version, _ = version_manager.create_schema(
            table_name=table_name, input_data=test_schema
        )

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
    def test_creates_major_version_schema(
        self, s3_client, glue_client, athena_client, input_data, expected
    ):
        s3_client.put_object(
            Body=json.dumps(test_glue_table_input),
            Bucket=self.bucket_name,
            Key="test_product/v1.0/test_table/schema.json",
        )

        version_manager = VersionManager(test_metadata["name"], logging.getLogger())

        with patch(
            "versioning.glue_client",
            glue_client,
        ):
            with patch(
                "versioning.athena_client",
                athena_client,
            ):
                version, changes, copy_response = version_manager.update_schema(
                    input_data, "test_table"
                )

        assert version == "v2.0"
        assert changes == expected
        assert copy_response == {"test_table copied": False}
        self.assert_has_keys(
            {
                "test_product/v2.0/metadata.json",
                "test_product/v2.0/test_table/schema.json",
            },
            "v2.0",
            data_product_name=test_metadata["name"],
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
        data_product_name,
        data_product_versions,
        data_product_major_versions,
        create_raw_and_curated_data,
    ):
        self.s3_client = s3_client
        self.bucket_name = metadata_bucket
        self.data_product_name = data_product_name
        self.latest_major_version = "v2"
        self.new_major_version = "v3"
        self.number_of_schemas = 3

        # Set up metadata and schema files for existing versions
        for version in data_product_versions:
            s3_client.put_object(
                Body=json.dumps(test_metadata_with_schemas),
                Bucket=self.bucket_name,
                Key=f"{data_product_name}/{version}/metadata.json",
            )
        for i in range(self.number_of_schemas):
            for version in data_product_versions:
                test_schema_with_input_data = test_schema | test_glue_table_input
                s3_client.put_object(
                    Body=json.dumps(test_schema_with_input_data),
                    Bucket=self.bucket_name,
                    Key=f"{data_product_name}/{version}/schema{i}/schema.json",
                )

        # Set up glue databases for major versions
        for major_version in data_product_major_versions:
            database_name = f"{data_product_name}_{major_version}"

            glue_client.create_database(DatabaseInput={"Name": database_name})

            for i in range(self.number_of_schemas):
                glue_client.create_table(
                    DatabaseName=database_name,
                    TableInput={"Name": f"schema{i}"},
                )

    @pytest.fixture(autouse=True)
    def setup_subject(self, glue_client, athena_client, data_product_name):
        with patch("glue_and_athena_utils.glue_client", glue_client):
            with patch("glue_and_athena_utils.athena_client", athena_client):
                
                self.version_manager = VersionManager(data_product_name, logger)
            yield

    def test_success(self):
        # The patches stub the sql calls to copy data over
        with patch(
            "curated_data.curated_data_loader.start_query_execution_and_wait"
        ) as mock_query:
            with patch(
                "curated_data.curated_data_loader.refresh_table_partitions"
            ) as mock_refresh:
                mock_query.return_value = "qidyes"
                mock_refresh.return_value = "qidyes"
                schema_list = ["schema0"]
                self.version_manager.update_metadata_remove_schemas(
                    schema_list=schema_list
                )

        schema_prefix = f"{self.data_product_name}/v2.0/metadata.json"
        self.assert_object_count(self.bucket_name, schema_prefix, 1)

    def test_invalid_schemas(self):
        schema_list = ["schema3", "schema4"]

        with pytest.raises(InvalidUpdate) as exc:
            self.version_manager.update_metadata_remove_schemas(schema_list=schema_list)
        assert (
            str(exc.value)
            == "Invalid schemas found in schema_list: ['schema3', 'schema4']"
        )

    def test_glue_table_not_found(self):
        schema_list = ["schema0", "banana"]
        with pytest.raises(InvalidUpdate):
            self.version_manager.update_metadata_remove_schemas(schema_list=schema_list)

    def test_data_files_not_deleted_from_existing_versions(self):
        curated_prefix = (
            f"curated/{self.data_product_name}/{self.latest_major_version}/schema0/"
        )
        raw_prefix = (
            f"raw/{self.data_product_name}/{self.latest_major_version}/schema0/"
        )
        schema_list = ["schema0"]

        self.assert_object_count(os.getenv("CURATED_DATA_BUCKET"), curated_prefix, 10)
        self.assert_object_count(os.getenv("RAW_DATA_BUCKET"), raw_prefix, 10)

        with patch(
            "curated_data.curated_data_loader.start_query_execution_and_wait"
        ) as mock_query:
            with patch(
                "curated_data.curated_data_loader.refresh_table_partitions"
            ) as mock_refresh:
                mock_query.return_value = "qidyes"
                mock_refresh.return_value = "qidyes"
                self.version_manager.update_metadata_remove_schemas(
                    schema_list=schema_list
                )

        self.assert_object_count(os.getenv("CURATED_DATA_BUCKET"), curated_prefix, 10)
        self.assert_object_count(os.getenv("RAW_DATA_BUCKET"), raw_prefix, 10)

    def test_deleted_schema_files_removed_from_new_version(
        self,
    ):
        schema_list = ["schema0"]

        with patch(
            "curated_data.curated_data_loader.start_query_execution_and_wait"
        ) as mock_query:
            with patch(
                "curated_data.curated_data_loader.refresh_table_partitions"
            ) as mock_refresh:
                mock_query.return_value = "qidyes"
                mock_refresh.return_value = "qidyes"
                self.version_manager.update_metadata_remove_schemas(
                    schema_list=schema_list
                )

        schema_prefix = f"{self.data_product_name}/v3.0/{schema_list[0]}/schema.json"
        self.assert_object_count(self.bucket_name, schema_prefix, 0)

    def test_deleted_table_removed_from_new_version(self):
        schema_list = ["schema0"]

        with patch(
            "curated_data.curated_data_loader.start_query_execution_and_wait"
        ) as mock_query:
            with patch(
                "curated_data.curated_data_loader.refresh_table_partitions"
            ) as mock_refresh:
                mock_query.return_value = "qidyes"
                mock_refresh.return_value = "qidyes"
                self.version_manager.update_metadata_remove_schemas(
                    schema_list=schema_list
                )

        expected_database_name = f"{self.data_product_name}_{self.new_major_version}"
        assert database_exists(expected_database_name, logger=logger)
        assert table_exists(expected_database_name, "schema1")
        assert not table_exists(expected_database_name, "schema0")

    def test_validate_other_schemas_are_upversioned(self):
        schema_list = ["schema0"]

        with patch(
            "curated_data.curated_data_loader.start_query_execution_and_wait"
        ) as mock_query:
            with patch(
                "curated_data.curated_data_loader.refresh_table_partitions"
            ) as mock_refresh:
                mock_query.return_value = "qidyes"
                mock_refresh.return_value = "qidyes"
                self.version_manager.update_metadata_remove_schemas(
                    schema_list=schema_list
                )

        for i in range(1, self.number_of_schemas):
            self.assert_object_exists(
                self.bucket_name,
                f"{self.data_product_name}/v3.0/schema{i}/schema.json",
            )

    def assert_object_count(self, bucket, prefix, expected_count):
        response = self.s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=prefix,
        )
        actual_count = response.get("KeyCount")
        assert actual_count == expected_count

    def assert_object_exists(self, bucket, key):
        return self.assert_object_count(bucket, key, 1)
