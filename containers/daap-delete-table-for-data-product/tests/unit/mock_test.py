import json
import os

from http import HTTPStatus

import boto3
import pytest
import delete_table


class TestHandler:
    @pytest.fixture(autouse=True)
    def setup_metadata_bucket(
        self,
        s3_client,
        metadata_bucket,
        data_product_name,
        table_name,
    ):
        s3_client.create_bucket(Bucket=metadata_bucket)
        s3_client.put_object(
            Bucket=os.environ.get("METADATA_BUCKET"),
            Key=f"{data_product_name}/v1.0/metadata.json",
            Body=json.dumps({"test": "test"}),
        )
        s3_client.put_object(
            Bucket=os.environ.get("METADATA_BUCKET"),
            Key=f"{data_product_name}/v1.0/{table_name}/schema.json",
            Body=json.dumps({"test": "test"}),
        )

    def test_metadata_and_schema_success(
        self, s3_client, event, data_product_name, fake_context
    ):
        response = delete_table.handler(event=event, context=fake_context)

        assert response["statusCode"] == HTTPStatus.OK
        assert json.loads(response["body"])["message"] == f"OK"

    def test_metadata_fail(
        self,
        s3_client,
        fake_data_product_event,
        fake_context,
        fake_data_product_name,
    ):
        response = delete_table.handler(
            event=fake_data_product_event, context=fake_context
        )
        assert response["statusCode"] == HTTPStatus.BAD_REQUEST
        assert (
            json.loads(response["body"])["error"]["message"]
            == f"Could not locate metadata for data product: {fake_data_product_name}."
        )

    def test_table_schema_fail(
        self,
        s3_client,
        fake_table_event,
        fake_context,
        fake_table_name,
    ):
        response = delete_table.handler(event=fake_table_event, context=fake_context)
        assert response["statusCode"] == HTTPStatus.BAD_REQUEST
        assert (
            json.loads(response["body"])["error"]["message"]
            == f"Could not locate valid schema for table: {fake_table_name}."
        )
