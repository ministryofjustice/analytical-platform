import json
import os

from http import HTTPStatus

import boto3
import pytest
import delete_table


class TestHandler:
    def test_success(
        self,
        s3_client,
        create_schema,
        create_glue_table,
        event,
        fake_context,
    ):
        response = delete_table.handler(event=event, context=fake_context)

        assert response["statusCode"] == HTTPStatus.OK
        assert json.loads(response["body"])["message"] == f"OK"

    def test_metadata_fail(
        self, s3_client, create_metadata_bucket, event, fake_context, data_product_name
    ):
        response = delete_table.handler(event=event, context=fake_context)
        assert response["statusCode"] == HTTPStatus.BAD_REQUEST
        assert (
            json.loads(response["body"])["error"]["message"]
            == f"Could not locate metadata for data product: {data_product_name}."
        )

    def test_table_schema_fail(
        self, s3_client, event, fake_context, table_name, create_metadata
    ):
        response = delete_table.handler(event=event, context=fake_context)
        assert response["statusCode"] == HTTPStatus.BAD_REQUEST
        assert (
            json.loads(response["body"])["error"]["message"]
            == f"Could not locate valid schema for table: {table_name}."
        )

    def test_delete_glue_table(
        self,
        event,
        fake_context,
        table_name,
        data_product_name,
        create_schema,
        create_glue_database,
    ):
        response = delete_table.handler(event=event, context=fake_context)
        assert response["statusCode"] == HTTPStatus.BAD_REQUEST
        assert (
            json.loads(response["body"])["error"]["message"]
            == f"Could not locate glue table '{table_name}' in database '{data_product_name}'"
        )
