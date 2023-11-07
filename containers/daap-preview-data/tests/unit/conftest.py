import os
import sys
from dataclasses import dataclass
from os.path import dirname, join
from unittest.mock import Mock

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
def athena_client():
    """
    Create a mock athena service
    """
    # Mock the Athena client and its methods
    athena_client = Mock()
    athena_client.returnvalue = athena_client

    # Define the expected response for starting the query execution
    expected_start_response = {"QueryExecutionId": "fake_query_execution_id"}
    athena_client.start_query_execution.return_value = expected_start_response

    # Define the expected response for getting the query execution state
    expected_state_response = {"QueryExecution": {"Status": {"State": "SUCCEEDED"}}}
    athena_client.get_query_execution.return_value = expected_state_response

    return athena_client


@pytest.fixture
def s3_client():
    """
    Create a mock s3 client
    """
    with mock_s3():
        client = boto3.client("s3", region_name="us-east-1")

        client.create_bucket(Bucket="test")
        client.put_object(
            Body="{}",
            Bucket="test",
            Key="data_product_metadata_spec/v1.1.0/moj_data_product_metadata_spec.json",
        )
        client.put_object(
            Body="{}",
            Bucket="test",
            Key="data_product_schema_spec/v1.0.0/moj_data_product_schema_spec.json",
        )

        yield client
