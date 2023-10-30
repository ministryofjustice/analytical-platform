import json
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

os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.environ["AWS_DEFAULT_REGION"] = "us-east-1"
os.environ["BUCKET_NAME"] = "test"

from data_platform_logging import DataPlatformLogger  # noqa E402
from data_platform_paths import DataProductElement  # noqa E402


@pytest.fixture(autouse=True)
def set_env_vars(monkeypatch):
    monkeypatch.setenv("RAW_DATA_BUCKET", "raw")
    monkeypatch.setenv("CURATED_DATA_BUCKET", "curated")
    monkeypatch.setenv("METADATA_BUCKET", "metadata")
    monkeypatch.setenv("LANDING_ZONE_BUCKET", "landing")
    monkeypatch.setenv("LOG_BUCKET", "logs")


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


@pytest.fixture
def logger():
    return DataPlatformLogger()


@pytest.fixture
def data_product_element(data_product_name, table_name):
    return DataProductElement.load(table_name, data_product_name)


@pytest.fixture
def region_name():
    return "eu-west-1"


@pytest.fixture
def create_metadata_bucket(s3_client):
    s3_client.create_bucket(Bucket=os.getenv("METADATA_BUCKET"))


@pytest.fixture
def create_raw_bucket(s3_client):
    s3_client.create_bucket(Bucket=os.getenv("RAW_DATA_BUCKET"))


@pytest.fixture
def create_curated_bucket(s3_client):
    s3_client.create_bucket(Bucket=os.getenv("CURATED_DATA_BUCKET"))


@pytest.fixture
def data_product_name():
    return "data-product"


@pytest.fixture
def table_name():
    return "table-name"


@pytest.fixture
def event(data_product_name, table_name):
    return {
        "headers": {"Content-Type": "application/json"},
        "pathParameters": {
            "data-product-name": data_product_name,
            "table-name": table_name,
        },
    }


@pytest.fixture
def data_product_versions():
    return {"v1.0", "v1.1", "v1.2"}


@pytest.fixture
def create_metadata(
    s3_client, create_metadata_bucket, data_product_name, data_product_versions
):
    for version in data_product_versions:
        s3_client.put_object(
            Bucket=os.environ.get("METADATA_BUCKET", "metadata"),
            Key=f"{data_product_name}/{version}/metadata.json",
            Body=json.dumps({"test": version}),
        )


@pytest.fixture
def create_schema(
    create_metadata, s3_client, data_product_name, table_name, data_product_versions
):
    for version in data_product_versions:
        s3_client.put_object(
            Bucket=os.getenv("METADATA_BUCKET"),
            Key=f"{data_product_name}/{version}/{table_name}/schema.json",
            Body=json.dumps({"test": version}),
        )


@pytest.fixture
def create_glue_database(glue_client, data_product_name):
    glue_client.create_database(DatabaseInput={"Name": data_product_name})


@pytest.fixture
def create_glue_table(create_glue_database, glue_client, data_product_name, table_name):
    glue_client.create_table(
        DatabaseName=data_product_name, TableInput={"Name": table_name}
    )


@pytest.fixture
def create_raw_data(
    s3_client, create_raw_bucket, data_product_name, table_name, data_product_versions
):
    for version in data_product_versions:
        for i in range(10):
            s3_client.put_object(
                Bucket=os.getenv("RAW_DATA_BUCKET"),
                Key=f"raw/{data_product_name}/{version}/{table_name}/raw-file-{str(i)}.json",
                Body=json.dumps({"content": f"{i}"}),
            )


@pytest.fixture
def create_curated_data(
    s3_client,
    create_curated_bucket,
    data_product_name,
    table_name,
    data_product_versions,
):
    for version in data_product_versions:
        for i in range(10):
            s3_client.put_object(
                Bucket=os.getenv("CURATED_DATA_BUCKET"),
                Key=f"curated/{data_product_name}/{version}/{table_name}/curated-file-{str(i)}.json",
                Body=json.dumps({"content": f"{i}"}),
            )


@pytest.fixture
def regenerate_schema_data(create_schema):
    pass
