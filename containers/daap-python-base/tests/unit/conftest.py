import os
import sys
import time
from os.path import dirname, join
from unittest.mock import patch

import boto3
import pytest
from moto import mock_s3

sys.path.append(join(dirname(__file__), "../", "../", "src", "var", "task"))

from data_platform_logging import DataPlatformLogger  # noqa E402
from data_platform_paths import DataProductElement  # noqa E402

os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.environ["AWS_LAMBDA_FUNCTION_NAME"] = "test_lambda"
os.environ["BUCKET_NAME"] = "bucket"
os.putenv("TZ", "Europe/London")
time.tzset()


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
