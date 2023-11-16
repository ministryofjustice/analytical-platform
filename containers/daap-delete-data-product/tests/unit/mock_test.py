import json
import os
from typing import Any

import delete_data_product
import pytest

test_metadata_with_schemas = {
    "name": "test_product",
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


def count_files(client, bucket, prefix):
    response = client.list_objects_v2(
        Bucket=bucket,
        Prefix=prefix,
    )
    return response.get("KeyCount")


class TestRemoveAllVersions:
    @pytest.fixture(autouse=True)
    def setup(
        self,
        s3_client,
        create_metadata_bucket,
        create_raw_bucket,
        create_curated_bucket,
        glue_client,
        data_product_name,
        data_product_versions,
    ):
        for version in data_product_versions:
            s3_client.put_object(
                Body=json.dumps(test_metadata_with_schemas),
                Bucket=os.getenv("METADATA_BUCKET"),
                Key=f"{data_product_name}/{version}/metadata.json",
            )
        for i in range(3):
            for version in data_product_versions:
                s3_client.put_object(
                    Body=json.dumps(test_schema),
                    Bucket=os.getenv("METADATA_BUCKET"),
                    Key=f"{data_product_name}/{version}/schema{i}/schema.json",
                )

    def test_success(
        self,
        s3_client,
        create_glue_tables,
        create_fail_data,
        create_raw_data,
        create_curated_data,
        data_product_name,
        glue_client,
        event,
        fake_context,
    ):
        # Call the handler
        result = delete_data_product.handler(event, fake_context)

        assert (
            json.loads(result.get("body"))["message"]
            == f"Successfully removed data product '{data_product_name}'."
        )

    def test_fail_files_are_deleted(
        self,
        s3_client,
        create_fail_data,
        data_product_name,
        fake_context,
        event,
    ):
        bucket = os.getenv("RAW_DATA_BUCKET")
        prefix = f"fail/{data_product_name}/"

        # Assert we have the correct number of fail files to begin with
        assert count_files(s3_client, bucket, prefix) == 30

        # Call the handler
        delete_data_product.handler(event, fake_context)

        # Assert that fail files have been deleted
        assert count_files(s3_client, bucket, prefix) == 0

    def test_raw_files_are_deleted(
        self,
        s3_client,
        create_raw_data,
        data_product_name,
        fake_context,
        event,
    ):
        bucket = os.getenv("RAW_DATA_BUCKET")
        prefix = f"raw/{data_product_name}/"

        # Assert we have the correct number of fail files to begin with
        assert count_files(s3_client, bucket, prefix) == 30

        # Call the handler
        delete_data_product.handler(event, fake_context)

        # Assert that fail files have been deleted
        assert count_files(s3_client, bucket, prefix) == 0

    def test_curated_files_are_deleted(
        self,
        s3_client,
        create_curated_data,
        data_product_name,
        fake_context,
        event,
    ):
        bucket = os.getenv("CURATED_DATA_BUCKET")
        prefix = f"curated/{data_product_name}/"

        # Assert we have the correct number of fail files to begin with
        assert count_files(s3_client, bucket, prefix) == 30

        # Call the handler
        delete_data_product.handler(event, fake_context)

        # Assert that fail files have been deleted
        assert count_files(s3_client, bucket, prefix) == 0

    def test_metadata_and_schema_files_are_deleted(
        self,
        s3_client,
        create_failed_raw_and_curated_data,
        data_product_name,
        fake_context,
        event,
    ):
        bucket = os.getenv("METADATA_BUCKET")
        prefix = f"{data_product_name}/"

        # Assert we have the correct number of fail files to begin with
        assert count_files(s3_client, bucket, prefix) == 12

        # Call the handler
        delete_data_product.handler(event, fake_context)

        # Assert that fail files have been deleted
        assert count_files(s3_client, bucket, prefix) == 0

    def test_database_is_deleted(
        self,
        event,
        fake_context,
        data_product_name,
        glue_client,
        create_failed_raw_and_curated_data,
        create_glue_tables,
    ):
        # Call the handler
        delete_data_product.handler(event, fake_context)

        with pytest.raises(glue_client.exceptions.EntityNotFoundException) as exc:
            glue_client.get_database(Name=data_product_name)
        assert (
            exc.value.response["Error"]["Message"]
            == f"Database {data_product_name} not found."
        )

    def test_delete_data_files_when_no_files_exist(
        self, s3_client, event, fake_context, data_product_name
    ):
        # Call the handler
        delete_data_product.handler(event, fake_context)

        # Test Curated
        bucket = os.getenv("CURATED_DATA_BUCKET")
        prefix = f"curated/{data_product_name}/"

        # Assert that fail files have been deleted
        assert count_files(s3_client, bucket, prefix) == 0

        # Test raw
        bucket = os.getenv("RAW_DATA_BUCKET")
        prefix = f"raw/{data_product_name}/"

        # Assert that fail files have been deleted
        assert count_files(s3_client, bucket, prefix) == 0

        # Test failed
        bucket = os.getenv("RAW_DATA_BUCKET")
        prefix = f"fail/{data_product_name}/"

        # Assert that fail files have been deleted
        assert count_files(s3_client, bucket, prefix) == 0
