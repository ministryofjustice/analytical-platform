import json
import os
import sys
import time
import urllib
from os.path import dirname, join
from unittest.mock import patch

import boto3
import pytest
from moto import mock_glue, mock_s3

sys.path.append(join(dirname(__file__), "../", "../", "src", "var", "task"))

os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.environ["AWS_LAMBDA_FUNCTION_NAME"] = "test_lambda"
os.environ["AWS_DEFAULT_REGION"] = "us-east-1"
os.environ["BUCKET_NAME"] = "bucket"
os.putenv("TZ", "Europe/London")
time.tzset()

from data_platform_logging import DataPlatformLogger  # noqa E402
from data_platform_paths import DataProductElement  # noqa E402
from data_product_metadata import DataProductMetadata  # noqa E402


@pytest.fixture
def region_name():
    return "eu-west-2"


@pytest.fixture(autouse=True)
def set_env_vars(monkeypatch):
    monkeypatch.setenv("RAW_DATA_BUCKET", "raw")
    monkeypatch.setenv("CURATED_DATA_BUCKET", "curated")
    monkeypatch.setenv("METADATA_BUCKET", "metadata")
    monkeypatch.setenv("LANDING_ZONE_BUCKET", "landing")
    monkeypatch.setenv("LOG_BUCKET", "logs")


@pytest.fixture
def data_product_metadata(s3_client, data_product_name, table_name, logger):
    return DataProductMetadata(
        data_product_name=data_product_name,
        logger=logger,
        input_data=None,
    ).load()


@pytest.fixture
def s3_client(region_name):
    """
    Create a mock s3 client
    """
    with mock_s3():
        client = boto3.client("s3", region_name=region_name)

        yield client


@pytest.fixture
def glue_client(region_name):
    """
    Create a mock glue catalogue
    """
    with mock_glue():
        client = boto3.client("glue", region_name=region_name)

        yield client


@pytest.fixture
def raw_table_metadata(raw_data_table):
    return {
        "DatabaseName": raw_data_table.database,
        "TableInput": {
            "Name": raw_data_table.name,
            "StorageDescriptor": {
                "Columns": [
                    {
                        "Name": "col1",
                        "Type": "type1",
                    },
                    {
                        "Name": "col2",
                        "Type": "type2",
                    },
                ]
            },
        },
    }


@pytest.fixture
def raw_data_table(data_product_element):
    return data_product_element.raw_data_table_unique()


@pytest.fixture
def data_product_element(region_name, s3_client):
    with patch("data_platform_paths.s3_client", s3_client):
        s3_client.create_bucket(
            Bucket=os.getenv("METADATA_BUCKET"),
            CreateBucketConfiguration={"LocationConstraint": region_name},
        )
        element = DataProductElement.load(element_name="foo", data_product_name="bar")
        return element


@pytest.fixture
def logger():
    return DataPlatformLogger()


def load_v1_metadata_schema_to_mock_s3(s3_client):
    with urllib.request.urlopen(
        "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-environments/main/terraform/environments/data-platform/data-product-metadata-json-schema/v1.0.0/moj_data_product_metadata_spec.json"  # noqa E501
    ) as url:
        data = json.load(url)
    json_data = json.dumps(data)
    s3_client.put_object(
        Body=json_data,
        Bucket=os.environ["METADATA_BUCKET"],
        Key="data_product_metadata_spec/v1.0.0/moj_data_product_metadata_spec.json",
    )


def load_v1_1_metadata_schema_to_mock_s3(s3_client):
    with urllib.request.urlopen(
        "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-environments/main/terraform/environments/data-platform/data-product-metadata-json-schema/v1.1.0/moj_data_product_metadata_spec.json"  # noqa E501
    ) as url:
        data = json.load(url)
    json_data = json.dumps(data)
    s3_client.put_object(
        Body=json_data,
        Bucket=os.environ["METADATA_BUCKET"],
        Key="data_product_metadata_spec/v1.1.0/moj_data_product_metadata_spec.json",
    )


def load_v1_schema_schema_to_mock_s3(s3_client):
    with urllib.request.urlopen(
        "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-environments/main/terraform/environments/data-platform/data-product-table-schema-json-schema/v1.0.0/moj_data_product_table_spec.json"  # noqa E501
    ) as url:
        data = json.load(url)
    json_data = json.dumps(data)
    s3_client.put_object(
        Body=json_data,
        Bucket=os.environ["METADATA_BUCKET"],
        Key="data_product_schema_spec/v1.0.0/moj_data_product_schema_spec.json",
    )


@pytest.fixture
def metadata_bucket(s3_client, region_name):
    bucket_name = os.environ["METADATA_BUCKET"]
    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )

    load_v1_metadata_schema_to_mock_s3(s3_client)
    load_v1_schema_schema_to_mock_s3(s3_client)

    return bucket_name


@pytest.fixture
def create_raw_bucket(s3_client, region_name):
    s3_client.create_bucket(
        Bucket=os.getenv("RAW_DATA_BUCKET"),
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )


@pytest.fixture
def create_curated_bucket(s3_client, region_name):
    s3_client.create_bucket(
        Bucket=os.getenv("CURATED_DATA_BUCKET"),
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )


@pytest.fixture
def create_glue_database(glue_client, data_product_name):
    glue_client.create_database(DatabaseInput={"Name": data_product_name})


@pytest.fixture
def create_glue_tables(create_glue_database, glue_client, data_product_name):
    for i in range(3):
        glue_client.create_table(
            DatabaseName=data_product_name, TableInput={"Name": f"schema{i}"}
        )


@pytest.fixture
def data_product_name():
    return "data-product"


@pytest.fixture
def table_name():
    return "table-name"


@pytest.fixture
def data_product_versions():
    return {"v1.0", "v1.1", "v1.2"}


@pytest.fixture
def create_raw_and_curated_data(
    s3_client,
    create_raw_bucket,
    create_curated_bucket,
    data_product_name,
    table_name,
    data_product_versions,
):
    for version in data_product_versions:
        for i in range(10):
            s3_client.put_object(
                Bucket=os.getenv("CURATED_DATA_BUCKET"),
                Key=f"curated/{data_product_name}/{version}/schema0/curated-file-{str(i)}.json",
                Body=json.dumps({"content": f"{i}"}),
            )
            s3_client.put_object(
                Bucket=os.getenv("RAW_DATA_BUCKET"),
                Key=f"raw/{data_product_name}/{version}/schema0/raw-file-{str(i)}.json",
                Body=json.dumps({"content": f"{i}"}),
            )
    load_v1_1_metadata_schema_to_mock_s3(s3_client)
