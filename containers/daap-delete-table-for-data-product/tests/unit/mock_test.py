import json
import os

from http import HTTPStatus

import boto3
import pytest
import delete_table


class TestHandler:
    def test_success(
        self,
        event,
        fake_context,
        table_name,
        s3_client,
        create_schema,
        create_glue_table,
        create_raw_data,
        create_curated_data,
    ):
        response = delete_table.handler(event=event, context=fake_context)

        assert response["statusCode"] == HTTPStatus.OK
        assert (
            json.loads(response["body"])["error"]["message"]
            == f"Successfully deleted table '{table_name}' and raw & curated data files"
        )

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

    def test_glue_table_fail(
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

    def test_deletion_of_raw_files(
        self,
        event,
        fake_context,
        logger,
        create_schema,
        create_glue_table,
        create_raw_data,
        create_curated_data,
        s3_client,
        data_product_element,
    ):
        bucket = os.environ.get("RAW_BUCKET", "raw")

        # Check that we have 10 files the bucket
        pre_delete_file_count = s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=data_product_element.raw_data_prefix.key,
        )
        assert len(pre_delete_file_count.get("Contents", [])) == 10

        # Call the handler
        delete_table.handler(event=event, context=fake_context)

        # Check that we no longer have the files in the bucket
        post_delete_file_count = s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=data_product_element.raw_data_prefix.key,
        )
        assert len(post_delete_file_count.get("Contents", [])) == 0

    def test_deletion_of_curated_files(
        self,
        event,
        fake_context,
        logger,
        create_schema,
        create_glue_table,
        create_raw_data,
        create_curated_data,
        s3_client,
        data_product_element,
    ):
        bucket = os.environ.get("CURATED_DATA_BUCKET", "curated")

        # Check that we have 10 files the bucket
        pre_delete_file_count = s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=data_product_element.curated_data_prefix.key,
        )
        assert len(pre_delete_file_count.get("Contents", [])) == 10

        # Call the handler
        delete_table.handler(event=event, context=fake_context)

        # Check that we no longer have the files in the bucket
        post_delete_file_count = s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=data_product_element.curated_data_prefix.key,
        )
        assert len(post_delete_file_count.get("Contents", [])) == 0
