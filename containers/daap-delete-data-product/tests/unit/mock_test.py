import json
import os
from typing import Any
from unittest.mock import patch

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


class TestRemoveAllVersions:
    @pytest.fixture(autouse=True)
    def setup(
        self,
        s3_client,
        glue_client,
        data_product_name,
        data_product_versions,
        create_metadata_bucket,
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
        create_failed_raw_and_curated_data,
        data_product_name,
        glue_client,
        event,
        fake_context,
    ):
        # Assert we have the correct number of database tables created
        tables = glue_client.get_tables(DatabaseName=data_product_name)
        assert len(tables["TableList"]) == 3

        # Assert we have the correct number of metadata files to begin with
        prefix = f"{data_product_name}/"
        response = s3_client.list_objects_v2(
            Bucket=os.getenv("METADATA_BUCKET"),
            Prefix=prefix,
        )
        assert response.get("KeyCount") == 12

        # Assert we have the correct number of fail files to begin with
        prefix = f"fail/{data_product_name}/"
        response = s3_client.list_objects_v2(
            Bucket=os.getenv("RAW_DATA_BUCKET"),
            Prefix=prefix,
        )
        assert response.get("KeyCount") == 30

        # Assert we have the correct number of raw files to begin with
        prefix = f"raw/{data_product_name}/"
        response = s3_client.list_objects_v2(
            Bucket=os.getenv("RAW_DATA_BUCKET"),
            Prefix=prefix,
        )
        assert response.get("KeyCount") == 30

        # Assert we have the correct number of curated files to begin with
        prefix = f"curated/{data_product_name}/"
        response = s3_client.list_objects_v2(
            Bucket=os.getenv("CURATED_DATA_BUCKET"),
            Prefix=prefix,
        )
        assert response.get("KeyCount") == 30

        ######################################################################
        # with patch("glue_utils.glue_client", glue_client):
        # Call the handler
        response = delete_data_product.handler(event, fake_context)

        # Assert that all metadata files have been deleted
        prefix = f"{data_product_name}/"
        response = s3_client.list_objects_v2(
            Bucket=os.getenv("METADATA_BUCKET"),
            Prefix=prefix,
        )
        assert response.get("KeyCount") == 0

        # Assert we have the correct number of fail files to begin with
        prefix = f"fail/{data_product_name}/"
        response = s3_client.list_objects_v2(
            Bucket=os.getenv("RAW_DATA_BUCKET"),
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

        assert (
            json.loads(response.get("body"))["message"]
            == f"Successfully removed data product '{data_product_name}'."
        )

    def test_error_400_when_metadata_does_not_exist(self, fake_event, fake_context):
        # Call the handler
        response = delete_data_product.handler(fake_event, fake_context)
        assert response.get("statusCode") == 400
        message = json.loads(response.get("body"))["error"]["message"]
        assert (
            message
            == "Could not locate metadata for data product: fake_data_product_name."
        )

    def test_database_does_not_exist(
        self,
        s3_client,
        glue_client,
        event,
        fake_context,
    ):
        with patch("glue_utils.glue_client", glue_client):
            response = delete_data_product.handler(event, fake_context)
            assert response.get("statusCode") == 400
            message = json.loads(response.get("body"))["error"]["message"]
            assert message == "Could not locate glue database 'data-product'"
