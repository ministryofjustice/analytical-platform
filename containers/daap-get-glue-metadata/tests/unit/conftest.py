import os
import sys
from dataclasses import dataclass
from os.path import dirname, join

import boto3
import pytest
from moto import mock_glue

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
