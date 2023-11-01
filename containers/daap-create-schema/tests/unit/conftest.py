import json
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
os.environ["AWS_DEFAULT_REGION"] = "us-east-1"
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
def method():
    return "POST"


@pytest.fixture
def body_content():
    return {"schema": {"TableDescription": "test_name"}}


@pytest.fixture
def fake_event(method, body_content):
    return {
        "httpMethod": method,
        "headers": {"Content-Type": "application/json"},
        "pathParameters": {"data-product-name": "test_p", "table-name": "test_t"},
        "body": json.dumps(body_content),
    }


@pytest.fixture
def s3_client():
    """
    Create a mock s3 client
    """
    with mock_s3():
        client = boto3.client("s3", region_name="us-east-1")

        yield client
