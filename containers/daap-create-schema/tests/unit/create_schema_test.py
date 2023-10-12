import json
import logging
import os
import urllib
from http import HTTPMethod
from unittest.mock import patch

import pytest
from create_schema import handler, s3_copy_folder_to_new_folder


def load_v1_schema_schema_to_mock_s3(bucket_name, s3_client):
    with urllib.request.urlopen(
        "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-environments/main/terraform/environments/data-platform/data-product-table-schema-json-schema/v1.0.0/moj_data_product_table_spec.json"  # noqa E501
    ) as url:
        data = json.load(url)
    json_data = json.dumps(data)
    s3_client.put_object(
        Body=json_data,
        Bucket=bucket_name,
        Key="data_product_schema_spec/v1.0.0/moj_data_product_schema_spec.json",
    )


def test_s3_copy_folder_to_new_folder(s3_client):
    bucket_name = os.environ["BUCKET_NAME"]
    s3_client.create_bucket(Bucket=bucket_name)
    for key in ["somefolder/v1.0/somefile1.json", "somefolder/v1.0/somefile2.json"]:
        s3_client.put_object(
            Body="b",
            Bucket=bucket_name,
            Key=key,
        )
        s3_client.put_object(
            Body="b",
            Bucket=bucket_name,
            Key=key,
        )
    with patch("create_schema.s3_client", s3_client):
        s3_copy_folder_to_new_folder(
            bucket_name, "somefolder/v1.0/", "v1.0", "v1.1", logging.getLogger()
        )

        for key in ["somefolder/v1.1/somefile1.json", "somefolder/v1.1/somefile2.json"]:
            try:
                s3_client.get_object(Bucket=bucket_name, Key=key)
                assert True
            except Exception:
                assert False


@pytest.mark.parametrize("method", [HTTPMethod.GET, HTTPMethod.PUT, HTTPMethod.DELETE])
def test_http_method_fail(fake_event, fake_context, method):
    response = handler(event=fake_event, context=fake_context)

    assert (
        json.loads(response["body"])["error"]["message"]
        == f"Sorry, {method} isn't allowed."
    )


def test_schema_already_exists(fake_event, fake_context, s3_client):
    bucket_name = os.environ["BUCKET_NAME"]
    s3_client.create_bucket(Bucket=bucket_name)
    load_v1_schema_schema_to_mock_s3(bucket_name, s3_client)

    with patch("create_schema.DataProductSchema") as mock_schema:
        mock_schema.return_value.exists = True
        response = handler(event=fake_event, context=fake_context)

    assert json.loads(response["body"])["error"]["message"] == (
        "v1 of this schema for table test_t already exists. You can upversion this schema if "
        "there are changes from v1 using the PUT method of this endpoint. Or if this is a different "
        "table then please choose a different name for it."
    )


def test_schema_does_not_exist_and_is_valid(fake_event, fake_context, s3_client):
    bucket_name = os.environ["BUCKET_NAME"]
    s3_client.create_bucket(Bucket=bucket_name)
    load_v1_schema_schema_to_mock_s3(bucket_name, s3_client)

    with patch("create_schema.DataProductSchema") as mock_schema:
        mock_schema.return_value.exists = False
        mock_schema.return_value.valid = True
        mock_schema.return_value.parent_product_has_registered_schema = False
        with patch("create_schema.DataProductMetadata") as mock_metadata:
            mock_metadata.return_value.load.latest_version_saved_data = {
                "name": "test_p"
            }
            response = handler(event=fake_event, context=fake_context)

    assert json.loads(response["body"])["message"] == (
        "Schema for test_t has been created in the test_p data product"
    )


def test_schema_not_valid(fake_event, fake_context, s3_client):
    bucket_name = os.environ["BUCKET_NAME"]
    s3_client.create_bucket(Bucket=bucket_name)
    load_v1_schema_schema_to_mock_s3(bucket_name, s3_client)

    with patch("create_schema.DataProductSchema") as mock_schema:
        mock_schema.return_value.exists = False
        mock_schema.return_value.valid = False
        mock_schema.return_value.parent_product_has_registered_schema = False

        response = handler(event=fake_event, context=fake_context)

    assert json.loads(response["body"])["error"]["message"][:65] == (
        "schema for test_t has failed validation with the following error:"
    )
