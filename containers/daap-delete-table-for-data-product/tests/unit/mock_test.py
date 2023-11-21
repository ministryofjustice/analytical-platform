import json
import os
from http import HTTPStatus

import delete_table
import pytest
<<<<<<< HEAD


def count_files(client, bucket, prefix):
    paginator = client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(
        Bucket=bucket,
        Prefix=prefix,
    )
    file_count = 0
    try:
        for page in page_iterator:
            file_count += page["KeyCount"]
    except KeyError:
        pass
    return file_count
=======
>>>>>>> 28c0ec5c (:memo: Update change logs and version files)


def count_files(client, bucket, prefix):
    paginator = client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(
        Bucket=bucket,
        Prefix=prefix,
    )
    file_count = 0
    try:
        for page in page_iterator:
            file_count += page["KeyCount"]
    except KeyError:
        pass
    return file_count


class TestHandler:
    def test_success(
        self,
        logger,
        event,
        fake_context,
        glue_client,
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

    def test_glue_table_deleted(
        self,
        logger,
        event,
        fake_context,
        glue_client,
        table_name,
        create_schema,
        create_glue_table,
        create_raw_data,
        create_curated_data,
        database_name,
    ):
        delete_table.handler(event=event, context=fake_context)
        with pytest.raises(glue_client.exceptions.EntityNotFoundException) as exception:
            glue_client.get_table(DatabaseName=database_name, Name=table_name)
        assert (
            exception.value.response["Error"]["Message"]
            == f"Table {table_name} not found."
        )

    @pytest.mark.parametrize(
        "bucket_name,file_type,pre_count,post_count",
        [
            ("RAW_DATA_BUCKET", "raw", 10, 0),
            ("CURATED_DATA_BUCKET", "curated", 10, 0),
        ],
    )
    def test_deletion_of_files(
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
        bucket_name,
        file_type,
        pre_count,
        post_count,
    ):
        bucket = os.getenv(bucket_name)
        for version in data_product_major_versions:
            prefix = f"{file_type}/{data_product_name}/{version}/{table_name}/"
            assert count_files(s3_client, bucket, prefix) == pre_count

        # Call the handler
        delete_table.handler(event=event, context=fake_context)

        for version in data_product_major_versions:
            prefix = f"{file_type}/{data_product_name}/{version}/{table_name}/"
            assert count_files(s3_client, bucket, prefix) == post_count

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
        delete_table.handler(event=event, context=fake_context)
        bucket = os.getenv("METADATA_BUCKET")
        prefix = f"{data_product_name}/v3.0/{table_name}/schema.json"

        assert count_files(s3_client, bucket, prefix) == 0

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
        delete_table.handler(event=event, context=fake_context)
        bucket = os.getenv("METADATA_BUCKET")
        prefix = f"{data_product_name}/v3.0/metadata.json"

        assert count_files(s3_client, bucket, prefix) == 1
