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

    @pytest.mark.parametrize(
        "bucket_name,file_type,pre_count,post_count",
        [
            ("RAW_DATA_BUCKET", "fail", 30, 0),
            ("RAW_DATA_BUCKET", "raw", 30, 0),
            ("CURATED_DATA_BUCKET", "curated", 30, 0),
            ("METADATA_BUCKET", "", 12, 0),
        ],
    )
    def test_files_are_deleted(
        self,
        s3_client,
        create_fail_data,
        create_raw_data,
        create_curated_data,
        data_product_name,
        fake_context,
        event,
        bucket_name,
        file_type,
        pre_count,
        post_count,
    ):
        bucket = os.getenv(bucket_name)
        if file_type:
            prefix = f"{file_type}/{data_product_name}/"
        else:
            prefix = f"{data_product_name}/"

        # Assert we have the correct number of fail files to begin with
        assert count_files(s3_client, bucket, prefix) == pre_count

        # Call the handler
        delete_data_product.handler(event, fake_context)

        # Assert that fail files have been deleted
        assert count_files(s3_client, bucket, prefix) == post_count

    def test_databases_are_deleted(
        self,
        event,
        fake_context,
        data_product_name,
        glue_client,
        create_glue_tables,
        database_names,
    ):
        # Call the handler
        delete_data_product.handler(event, fake_context)

        with pytest.raises(glue_client.exceptions.EntityNotFoundException) as exception:
            for database_name in database_names:
                glue_client.get_database(Name=database_name)
        assert (
            exception.value.response["Error"]["Message"]
            == f"Database {database_name} not found."
        )

    @pytest.mark.parametrize(
        "bucket_name,file_type,count",
        [
            ("CURATED_DATA_BUCKET", "curated", 0),
            ("RAW_DATA_BUCKET", "raw", 0),
            ("RAW_DATA_BUCKET", "fail", 0),
        ],
    )
    def test_delete_data_files_when_no_files_exist(
        self,
        s3_client,
        event,
        fake_context,
        data_product_name,
        bucket_name,
        file_type,
        count,
    ):
        bucket = os.getenv(bucket_name)
        prefix = f"{file_type}/{data_product_name}/"
        # Assert that no files have been created
        assert count_files(s3_client, bucket, prefix) == count

        # Call the handler
        result = delete_data_product.handler(event, fake_context)

        assert (
            json.loads(result.get("body"))["message"]
            == f"Successfully removed data product '{data_product_name}'."
        )
