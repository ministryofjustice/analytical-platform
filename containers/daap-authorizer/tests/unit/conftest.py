import sys
from dataclasses import dataclass
from os import environ
from os.path import dirname, join

import pytest

sys.path.append(join(dirname(__file__), "../", "../", "src", "var", "task"))
sys.path.append(
    join(
        dirname(__file__), "../", "../", "../", "daap-python-base", "src", "var", "task"
    )
)

environ["LOG_BUCKET"] = "log"
environ["AWS_ACCESS_KEY_ID"] = "testing"
environ["AWS_SECRET_ACCESS_KEY"] = "testing"
environ["AWS_SECURITY_TOKEN"] = "testing"
environ["AWS_SESSION_TOKEN"] = "testing"
environ["AWS_DEFAULT_REGION"] = "us-east-1"


@dataclass
class FakeContext:
    function_name: str


@pytest.fixture
def fake_context():
    """
    Emulate the context object passed
    """
    return FakeContext(function_name="some-function")
