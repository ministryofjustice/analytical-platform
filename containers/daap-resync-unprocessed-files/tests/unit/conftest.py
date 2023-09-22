import os
import sys
from dataclasses import dataclass
from os.path import dirname, join
from unittest.mock import MagicMock

import boto3
import pytest
from moto import mock_s3

os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.environ["AWS_DEFAULT_REGION"] = "us-east-1"
os.environ["BUCKET_NAME"] = "test"

sys.path.append(join(dirname(__file__), "../", "../", "src", "var", "task"))
sys.path.append(
    join(
        dirname(__file__), "../", "../", "../", "daap-python-base", "src", "var", "task"
    )
)

from data_platform_paths import DataProductConfig  # noqa: E402


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
def s3_client():
    """
    Create a mock s3 catalogue
    """
    with mock_s3():
        client = boto3.client("s3", region_name="us-east-1")

        yield client


@pytest.fixture
def bucket_name():
    return "bucket"


@pytest.fixture
def data_product(bucket_name):
    return DataProductConfig("data_product", "table_name", bucket_name)
