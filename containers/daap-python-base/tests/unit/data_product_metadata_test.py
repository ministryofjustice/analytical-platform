import json
import logging
import urllib.request
from tempfile import NamedTemporaryFile

import data_product_metadata
import pytest
from data_product_metadata import DataProductMetadata

test_schema_pass = {
    "name": "test_product",
    "description": "just testing the metadata json validation/registration",
    "domain": "MoJ",
    "dataProductOwner": "matthew.laverty@justice.gov.uk",
    "dataProductOwnerDisplayName": "matt laverty",
    "email": "matthew.laverty@justice.gov.uk",
    "status": "draft",
    "dpiaRequired": False
}

test_schema_fail = {
    "name": "test_product(bad name)",
    "description": "just testing the metadata json validation/registration",
    "domain": "MoJ",
    "dataProductOwner": "matthew.laverty@justice.gov.uk",
    "dataProductOwnerDisplayName": "matt laverty",
    "email": "matthew.laverty@justice.gov.uk",
    "status": "draft",
    "dpiaRequired": False
}

def load_v1_metadata_schema_to_mock_s3(bucket_name, s3_client):
    with urllib.request.urlopen("https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-environments/main/terraform/environments/data-platform/data-product-metadata-json-schema/v1.0.0/moj_data_product_metadata_spec.json") as url:
        data = json.load(url)
    json_data = json.dumps(data)
    s3_client.put_object(
        Body=json_data,
        Bucket=bucket_name,
        Key="data_product_metadata_spec/v1.0.0/moj_data_product_metadata_spec.json"
    )


def setup_bucket(name, s3_client, region_name, monkeypatch):
    bucket_name = name
    monkeypatch.setenv("BUCKET_NAME", bucket_name)

    # Emulate the data product being set up in the bucket
    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )


def test_get_latest_metadata_spec_path(monkeypatch):
    bucket_name = "bucket"
    monkeypatch.setenv("BUCKET_NAME", bucket_name)
    monkeypatch.setattr(
        data_product_metadata,
        "get_filepaths_from_s3_folder",
        lambda _name: ["v1.1/foo/bar", "v2.2/foo/bar", "v2.10/foo/bar"],
    )

    path = data_product_metadata.get_data_product_metadata_spec_path()
    assert (
        path
        == "s3://bucket/data_product_metadata_spec/v2.10/moj_data_product_metadata_spec.json"
    )


def test_get_specific_metadata_spec_path(monkeypatch):
    bucket_name = "bucket"
    monkeypatch.setenv("BUCKET_NAME", bucket_name)
    monkeypatch.setattr(
        data_product_metadata,
        "get_filepaths_from_s3_folder",
        lambda _name: ["v1/foo/bar", "v2/foo/bar"],
    )

    path = data_product_metadata.get_data_product_metadata_spec_path("v1")
    assert (
        path
        == "s3://bucket/data_product_metadata_spec/v1/moj_data_product_metadata_spec.json"
    )


def test_metadata_exist(s3_client, region_name, monkeypatch):
    bucket_name = "bucket"
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)

    # populate some folders & files to mock s3 bucket
    file_text = json.dumps(test_schema_pass)
    with NamedTemporaryFile(delete=True, suffix=".json") as tmp:
        with open(tmp.name, "w", encoding="UTF-8") as f:
            f.write(file_text)

        s3_client.upload_file(
            tmp.name, bucket_name, "metadata/test_product/v1.0/metadata.json"
        )

    md = DataProductMetadata(test_schema_pass["name"], logging.getLogger())
    assert md.metadata_exists


def test_metadata_does_not_exist(s3_client, region_name, monkeypatch):
    bucket_name = "bucket"
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)
    md = DataProductMetadata(test_schema_pass["name"], logging.getLogger())
    assert not md.metadata_exists


validation_inputs =[(test_schema_pass, True), (test_schema_fail, False)]
# expected_outputs = [True, False]

@pytest.mark.parametrize("test_schema, expected_out", validation_inputs)
def test_valid_metadata(test_schema, expected_out, s3_client, region_name, monkeypatch):
    bucket_name = "bucket"
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)
    load_v1_metadata_schema_to_mock_s3(bucket_name, s3_client)
    md = DataProductMetadata(test_schema["name"], logging.getLogger())
    md.validate(test_schema)
    assert md.valid_metadata == expected_out


def test_write_json_to_s3(s3_client, region_name, monkeypatch):
    bucket_name = "bucket"
    setup_bucket(bucket_name, s3_client, region_name, monkeypatch)
    load_v1_metadata_schema_to_mock_s3(bucket_name, s3_client)
    md = DataProductMetadata(test_schema_pass["name"], logging.getLogger())
    md.validate(test_schema_pass)
    md.write_json_to_s3()

    response = s3_client.get_object(
        Bucket=bucket_name, Key="metadata/test_product/v1.0/metadata.json"
    )
    data = response.get("Body").read().decode("utf-8")
    from_s3 = json.loads(data)

    assert test_schema_pass == from_s3
