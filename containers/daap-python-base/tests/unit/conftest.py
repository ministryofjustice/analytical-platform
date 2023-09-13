import os
import sys
import time
from os.path import dirname, join

import boto3
import pytest
from moto import mock_s3

sys.path.append(join(dirname(__file__), "../", "../", "src", "var", "task"))


os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.putenv("TZ", "Europe/London")
time.tzset()


@pytest.fixture
def region_name():
    return "eu-west-1"


@pytest.fixture
def s3_client(region_name):
    """
    Create a mock s3 client
    """
    with mock_s3():
        client = boto3.client("s3", region_name=region_name)

        yield client
