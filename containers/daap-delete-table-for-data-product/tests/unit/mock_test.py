import json
import os
from http import HTTPStatus

import delete_table


class TestHandler:
    def test_success(
        self,
        logger,
        event,
        fake_context,
        table_name,
        create_schema,
        create_glue_table,
        create_raw_data,
        create_curated_data,
    ):
        response = delete_table.handler(event=event, context=fake_context)

        assert response["statusCode"] == HTTPStatus.OK
        assert (
            json.loads(response["body"])["message"]
            == "Successfully removed table 'table-name', data files and generated new matadata version 'v3.0'"
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

    def test_ignores_missing_glue_table(
        self,
        event,
        fake_context,
        table_name,
        data_product_name,
        create_schema,
        create_glue_database,
    ):
        response = delete_table.handler(event=event, context=fake_context)
        assert response["statusCode"] == HTTPStatus.OK

    def test_does_not_delete_raw_files(
        self,
        event,
        fake_context,
        logger,
        create_schema,
        create_glue_table,
        create_raw_data,
        create_curated_data,
        s3_client,
        data_product_name,
        table_name,
        data_product_major_versions,
    ):
        bucket = os.getenv("RAW_DATA_BUCKET")
        for version in data_product_major_versions:
            prefix = f"raw/{data_product_name}/{version}/{table_name}/"
            response = s3_client.list_objects_v2(
                Bucket=bucket,
                Prefix=prefix,
            )
            assert response.get("KeyCount") == 10

        # Call the handler
        delete_table.handler(event=event, context=fake_context)

        for version in data_product_major_versions:
            prefix = f"raw/{data_product_name}/{version}/{table_name}/"
            response = s3_client.list_objects_v2(
                Bucket=bucket,
                Prefix=prefix,
            )
            assert response.get("KeyCount") == 10

    def test_does_not_delete_curated_files(
        self,
        event,
        fake_context,
        logger,
        create_schema,
        create_glue_table,
        create_raw_data,
        create_curated_data,
        s3_client,
        data_product_name,
        table_name,
        data_product_major_versions,
    ):
        bucket = os.getenv("CURATED_DATA_BUCKET")

        for version in data_product_major_versions:
            prefix = f"curated/{data_product_name}/{version}/{table_name}/"
            response = s3_client.list_objects_v2(
                Bucket=bucket,
                Prefix=prefix,
            )
            assert response.get("KeyCount") == 10

        # Call the handler
        delete_table.handler(event=event, context=fake_context)

        for version in data_product_major_versions:
            prefix = f"curated/{data_product_name}/{version}/{table_name}/"
            response = s3_client.list_objects_v2(
                Bucket=bucket,
                Prefix=prefix,
            )
            assert response.get("KeyCount") == 10

    def test_deletion_of_old_schema_version(
        self,
        s3_client,
        event,
        fake_context,
        logger,
        create_schema,
        create_glue_table,
        create_raw_data,
        create_curated_data,
        data_product_name,
        table_name,
        data_product_versions,
    ):
        # Call the handler
        response = delete_table.handler(event=event, context=fake_context)
        bucket = os.getenv("METADATA_BUCKET")

        # Validate that v3.0 of schema.json doesnt exist
        schema_prefix = f"{data_product_name}/v3.0/{table_name}/schema.json"
        response = s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=schema_prefix,
        )
        assert response.get("KeyCount") == 0

    def test_major_version_update_of_metadata(
        self,
        s3_client,
        event,
        fake_context,
        logger,
        create_schema,
        create_glue_table,
        create_raw_data,
        create_curated_data,
        data_product_name,
        table_name,
    ):
        # Call the handler
        response = delete_table.handler(event=event, context=fake_context)
        bucket = os.getenv("METADATA_BUCKET")

        # Check that v2.0 of metadata.json exists.
        metadata_prefix = f"{data_product_name}/v2.0/metadata.json"
        response = s3_client.list_objects_v2(
            Bucket=bucket,
            Prefix=metadata_prefix,
        )
        assert response.get("KeyCount") == 1
