import os
import sys
from dataclasses import dataclass
from os.path import dirname, join

import boto3
import pytest
from moto import mock_athena, mock_glue, mock_s3

sys.path.append(join(dirname(__file__), "../", "../", "src", "var", "task"))
sys.path.append(
    join(
        dirname(__file__), "../", "../", "../", "daap-python-base", "src", "var", "task"
    )
)

from data_platform_logging import DataPlatformLogger  # noqa E402
from data_platform_paths import DataProductElement  # noqa E402

os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.environ["AWS_DEFAULT_REGION"] = "us-east-1"
os.environ["BUCKET_NAME"] = "bucket"


@dataclass
class FakeContext:
    function_name: str


@pytest.fixture
def fake_context():
    """
    Emulate the context object passed
    """
    return FakeContext(function_name="some-function")


@pytest.fixture
def glue_client():
    """
    Create a mock glue catalogue
    """
    with mock_glue():
        client = boto3.client("glue", region_name="us-east-1")

        yield client


@pytest.fixture
def s3_client():
    """
    Create a mock s3 service
    """
    with mock_s3():
        client = boto3.client("s3", region_name="us-east-1")

        yield client


@pytest.fixture
def athena_client():
    """
    Create a mock athena service
    """
    with mock_athena():
        client = boto3.client("athena", region_name="us-east-1")

        yield client


@pytest.fixture(autouse=True)
def data_bucket(s3_client):
    os.environ["RAW_DATA_BUCKET"] = "data"
    os.environ["CURATED_DATA_BUCKET"] = "data"
    s3_client.create_bucket(Bucket="data")


@pytest.fixture(autouse=True)
def metadata_bucket(s3_client):
    os.environ["METADATA_BUCKET"] = "meta"
    s3_client.create_bucket(Bucket="meta")


@pytest.fixture
def data_product_element():
    return DataProductElement.load(element_name="foo", data_product_name="bar")


@pytest.fixture
def logger():
    return DataPlatformLogger()


@pytest.fixture
def raw_data_table(data_product_element):
    return data_product_element.raw_data_table_unique()
