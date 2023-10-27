import os
import sys
from dataclasses import dataclass
from os.path import dirname, join

import pytest
from unittest.mock import Mock


sys.path.append(join(dirname(__file__), "../", "../", "src", "var", "task"))
sys.path.append(
    join(
        dirname(__file__), "../", "../", "../", "daap-python-base", "src", "var", "task"
    )
)

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
def athena_client():
    """
    Create a mock athena service
    """
    # Mock the Athena client and its methods
    athena_client = Mock()
    return athena_client
