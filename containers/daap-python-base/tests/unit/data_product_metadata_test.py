import json
import logging
import os
import urllib.request
from tempfile import NamedTemporaryFile
from unittest.mock import patch

import data_product_metadata
import pytest
from data_platform_paths import JsonSchemaName
from data_product_metadata import DataProductMetadata, DataProductSchema

test_metadata_pass = {
    "name": "test_product",
    "description": "just testing the metadata json validation/registration",
    "domain": "MoJ",
    "dataProductOwner": "matthew.laverty@justice.gov.uk",
    "dataProductOwnerDisplayName": "matt laverty",
    "email": "matthew.laverty@justice.gov.uk",
    "status": "draft",
    "dpiaRequired": False,
}

test_metadata_fail = {
    "name": "test_product(bad name)",
    "description": "just testing the metadata json validation/registration",
    "domain": "MoJ",
    "dataProductOwner": "matthew.laverty@justice.gov.uk",
    "dataProductOwnerDisplayName": "matt laverty",
    "email": "matthew.laverty@justice.gov.uk",
    "status": "draft",
    "dpiaRequired": False,
}

test_schema_pass = {
    # "DatabaseName": "test_pass_db",
    # "TableName": "test_pass_tbl",
    "TableDescription": "table has schema to pass test",
    "Columns": [
        {
            "name": "col_1",
            "data_type": "bigint",
            "description": "ABCDEFGHIJKLMNOPQRSTUVWXY",
        },
        {"name": "col_2", "data_type": "tinyint", "description": "ABCDEFGHIJKL"},
        {
            "name": "col_3",
            "data_type": "int",
            "description": "ABCDEFGHIJKLMNOPQRSTUVWX",
        },
        {"name": "col_4", "data_type": "smallint", "description": "ABCDEFGHIJKLMN"},
    ],
}

test_schema_fail = {
    # "DatabaseName": "test_pass+db",
    # "TableName": "test_pass_tbl",
    "TableDescription": "table has schema to pass test",
    "Columns": [
        {
            "name": "col()()_1",
            "data_type": "bigint",
            "description": "ABCDEFGHIJKLMNOPQRSTUVWXY",
        },
        {"name": "col_2", "data_type": "tinyint", "description": "ABCDEFGHIJKL"},
        {
            "name": "col_3",
            "data_type": "int",
            "description": "ABCDEFGHIJKLMNOPQRSTUVWX",
        },
        {"name": "col_4", "data_type": "smallint", "description": "ABCDEFGHIJKLMN"},
    ],
}


def load_v1_metadata_schema_to_mock_s3(bucket_name, s3_client):
    with urllib.request.urlopen(
        "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-environments/main/terraform/environments/data-platform/data-product-metadata-json-schema/v1.0.0/moj_data_product_metadata_spec.json"  # noqa E501
    ) as url:
        data = json.load(url)
    json_data = json.dumps(data)
    s3_client.put_object(
        Body=json_data,
        Bucket=bucket_name,
        Key="data_product_metadata_spec/v1.0.0/moj_data_product_metadata_spec.json",
    )


def load_v1_schema_schema_to_mock_s3(bucket_name, s3_client):
    with urllib.request.urlopen(
        "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-environments/dpl-1194-create-table-schema/terraform/environments/data-platform/data-product-table-schema-json-schema/v1.0.0/moj_data_product_table_spec.json"  # noqa E501
    ) as url:
        data = json.load(url)
    json_data = json.dumps(data)
    s3_client.put_object(
        Body=json_data,
        Bucket=bucket_name,
        Key="data_product_schema_spec/v1.0.0/moj_data_product_schema_spec.json",
    )


def setup_bucket(name, s3_client, region_name, monkeypatch):
    bucket_name = name
    monkeypatch.setenv("BUCKET_NAME", bucket_name)

    # Emulate the data product being set up in the bucket
    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )


@pytest.mark.parametrize(
    "spec_type, expected_out",
    [
        (
            JsonSchemaName("metadata"),
            "s3://metadata/data_product_metadata_spec/v2.10/moj_data_product_metadata_spec.json",
        ),
        (
            JsonSchemaName("schema"),
            "s3://metadata/data_product_schema_spec/v2.10/moj_data_product_schema_spec.json",
        ),
    ],
)
def test_get_latest_metadata_spec_path(spec_type, expected_out, monkeypatch):
    monkeypatch.setattr(
        data_product_metadata,
        "get_filepaths_from_s3_folder",
        lambda _name: ["v1.1/foo/bar", "v2.2/foo/bar", "v2.10/foo/bar"],
    )

    path = data_product_metadata.get_data_product_specification_path(spec_type)
    assert path == expected_out


@pytest.mark.parametrize(
    "spec_type, expected_out",
    [
        (
            JsonSchemaName("metadata"),
            "s3://metadata/data_product_metadata_spec/v1/moj_data_product_metadata_spec.json",
        ),
        (
            JsonSchemaName("schema"),
            "s3://metadata/data_product_schema_spec/v1/moj_data_product_schema_spec.json",
        ),
    ],
)
def test_get_specific_metadata_spec_path(spec_type, expected_out):
    path = data_product_metadata.get_data_product_specification_path(spec_type, "v1")
    assert path == expected_out


def test_metadata_exist(s3_client, region_name, monkeypatch):
    bucket_name = os.getenv("METADATA_BUCKET")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)

    # populate some folders & files to mock s3 bucket
    file_text = json.dumps(test_metadata_pass)
    with NamedTemporaryFile(delete=True, suffix=".json") as tmp:
        with open(tmp.name, "w", encoding="UTF-8") as f:
            f.write(file_text)

        s3_client.upload_file(tmp.name, bucket_name, "test_product/v1.0/metadata.json")

    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        md = DataProductMetadata(test_metadata_pass["name"], logging.getLogger())
        assert md.exists


def test_metadata_does_not_exist(s3_client, region_name, monkeypatch):
    bucket_name = os.getenv("METADATA_BUCKET")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)
    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        md = DataProductMetadata(test_metadata_pass["name"], logging.getLogger())
        assert not md.exists


validation_md_inputs = [(test_metadata_pass, True), (test_metadata_fail, False)]


@pytest.mark.parametrize("test_metadata, expected_out", validation_md_inputs)
def test_valid_metadata(
    test_metadata, expected_out, s3_client, region_name, monkeypatch
):
    bucket_name = os.getenv("METADATA_BUCKET")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)
    load_v1_metadata_schema_to_mock_s3(bucket_name, s3_client)
    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        md = DataProductMetadata(test_metadata["name"], logging.getLogger())
        md.validate(test_metadata)
        assert md.valid == expected_out


validation_schema_inputs = [(test_schema_pass, True), (test_schema_fail, False)]


@pytest.mark.parametrize("test_schema, expected_out", validation_schema_inputs)
def test_valid_schema(test_schema, expected_out, s3_client, region_name, monkeypatch):
    bucket_name = os.getenv("METADATA_BUCKET")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)
    load_v1_schema_schema_to_mock_s3(bucket_name, s3_client)
    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        md = DataProductSchema(
            data_product_name="test_product",
            table_name="test_table",
            logger=logging.getLogger(),
        )
        md.validate(test_schema)
        assert md.valid == expected_out


def test_write_json_to_s3(s3_client, region_name, monkeypatch):
    bucket_name = os.getenv("METADATA_BUCKET")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)
    load_v1_metadata_schema_to_mock_s3(bucket_name, s3_client)
    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        md = DataProductMetadata(test_metadata_pass["name"], logging.getLogger())
        md.validate(test_metadata_pass)
        md.write_json_to_s3()

    response = s3_client.get_object(
        Bucket=bucket_name, Key="test_product/v1.0/metadata.json"
    )
    data = response.get("Body").read().decode("utf-8")
    from_s3 = json.loads(data)

    assert test_metadata_pass == from_s3


@pytest.mark.parametrize(
    "data_product_name, expected_output",
    [("test_product", True), ("test_product2", False)],
)
def test_does_data_product_metadata_exist(
    data_product_name, expected_output, s3_client, region_name, monkeypatch
):
    # with patch("data_product_metadata.s3_client", s3_client):
    bucket_name = os.getenv("METADATA_BUCKET")
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)

    # populate some folders & files to mock s3 bucket
    file_text = json.dumps(test_metadata_pass)
    with NamedTemporaryFile(delete=True, suffix=".json") as tmp:
        with open(tmp.name, "w", encoding="UTF-8") as f:
            f.write(file_text)

        s3_client.upload_file(tmp.name, bucket_name, "test_product/v1.0/metadata.json")

    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        schema = DataProductSchema(data_product_name, "test_table", logging.getLogger())
        assert schema.has_registered_data_product == expected_output


def test_convert_schema_to_glue_table_input_csv():
    pass
