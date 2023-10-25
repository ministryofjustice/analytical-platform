import json
import os
import sys
import time
import urllib
from os.path import dirname, join
from unittest.mock import patch

import boto3
import pytest
from moto import mock_s3

sys.path.append(join(dirname(__file__), "../", "../", "src", "var", "task"))

os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.environ["AWS_LAMBDA_FUNCTION_NAME"] = "test_lambda"
os.environ["BUCKET_NAME"] = "bucket"
os.putenv("TZ", "Europe/London")
time.tzset()

from data_platform_logging import DataPlatformLogger  # noqa E402
from data_platform_paths import DataProductElement  # noqa E402


@pytest.fixture
def region_name():
    return "eu-west-2"


@pytest.fixture(autouse=True)
def set_env_vars(monkeypatch):
    monkeypatch.setenv("RAW_DATA_BUCKET", "raw")
    monkeypatch.setenv("CURATED_DATA_BUCKET", "curated")
    monkeypatch.setenv("METADATA_BUCKET", "metadata")
    monkeypatch.setenv("LANDING_ZONE_BUCKET", "landing")
    monkeypatch.setenv("LOG_BUCKET", "logs")


@pytest.fixture
def s3_client(region_name):
    """
    Create a mock s3 client
    """
    with mock_s3():
        client = boto3.client("s3", region_name=region_name)

        yield client


@pytest.fixture
def raw_table_metadata(raw_data_table):
    return {
        "DatabaseName": raw_data_table.database,
        "TableInput": {
            "Name": raw_data_table.name,
            "StorageDescriptor": {
                "Columns": [
                    {
                        "Name": "col1",
                        "Type": "type1",
                    },
                    {
                        "Name": "col2",
                        "Type": "type2",
                    },
                ]
            },
        },
    }


@pytest.fixture
def raw_data_table(data_product_element):
    return data_product_element.raw_data_table_unique()


@pytest.fixture
def data_product_element(region_name, s3_client):
    with patch("data_platform_paths.s3", s3_client):
        s3_client.create_bucket(
            Bucket=os.getenv("METADATA_BUCKET"),
            CreateBucketConfiguration={"LocationConstraint": region_name},
        )
        element = DataProductElement.load(element_name="foo", data_product_name="bar")
        return element


@pytest.fixture
def logger():
    return DataPlatformLogger()


@pytest.fixture
def load_v1_metadata_schema_to_mock_s3(s3_client):
    with urllib.request.urlopen(
        "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-environments/main/terraform/environments/data-platform/data-product-metadata-json-schema/v1.0.0/moj_data_product_metadata_spec.json"  # noqa E501
    ) as url:
        data = json.load(url)
    json_data = json.dumps(data)
    s3_client.put_object(
        Body=json_data,
        Bucket=os.environ["METADATA_BUCKET"],
        Key="data_product_metadata_spec/v1.0.0/moj_data_product_metadata_spec.json",
    )


@pytest.fixture
def load_v1_schema_schema_to_mock_s3(s3_client):
    with urllib.request.urlopen(
        "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-environments/main/terraform/environments/data-platform/data-product-table-schema-json-schema/v1.0.0/moj_data_product_table_spec.json"  # noqa E501
    ) as url:
        data = json.load(url)
    json_data = json.dumps(data)
    s3_client.put_object(
        Body=json_data,
        Bucket=os.environ["METADATA_BUCKET"],
        Key="data_product_schema_spec/v1.0.0/moj_data_product_schema_spec.json",
    )


@pytest.fixture
def metadata_bucket(s3_client, region_name):
    bucket_name = os.environ["METADATA_BUCKET"]

    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )

    return bucket_name
