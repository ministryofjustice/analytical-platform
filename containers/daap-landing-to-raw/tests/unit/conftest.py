import os
import sys
from dataclasses import dataclass
from os.path import dirname, join

import boto3
import pytest
from moto import mock_s3

sys.path.append(join(dirname(__file__), "../", "../", "src", "var", "task"))
sys.path.append(
    join(
        dirname(__file__), "../", "../", "../", "daap-python-base", "src", "var", "task"
    )
)


os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.environ["BUCKET_NAME"] = "test"


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
def region_name():
    return "us-east-1"


@pytest.fixture(autouse=True)
def metadata_bucket(s3_client):
    """The pathing objects check for the latest version of metadata
    for a data product on instantiation"""
    metadata_bucket_name = "metadata"
    s3_client.create_bucket(Bucket=metadata_bucket_name)
    s3_client.put_object(
        Bucket=metadata_bucket_name,
        Key="metadata/data-product/v1.0/metadata.json",
        Body=r"{\"key\":\"value\"}",
    )


@pytest.fixture
def s3_client(region_name):
    """
    Create a mock s3 client
    """
    with mock_s3():
        client = boto3.client("s3", region_name=region_name)

        yield client
