import json
import os
import uuid

import boto3
from freezegun import freeze_time
from presigned_url import handler


@freeze_time("2023-01-01")
def test_success(s3_client, fake_context, region_name, monkeypatch):
    bucket_name = "bucket"
    database = "database1"
    table = "table1"
    filename = "testdata.csv"
    a_uuid = uuid.uuid4()
    monkeypatch.setattr(boto3, "client", lambda _name: s3_client)
    monkeypatch.setenv("BUCKET_NAME", bucket_name)
    monkeypatch.setattr(uuid, "uuid4", lambda: a_uuid)

    # Emulate the data product registration
    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )
    s3_client.put_object(
        Bucket=bucket_name,
        Key=f"{database}/v1.0/metadata.json",
        Body=json.dumps({"test": "test"}),
    )

    event = {
        "pathParameters": {
            "data-product-name": database,
            "table-name": table,
        },
        "body": json.dumps(
            {
                "filename": filename,
                "contentMD5": "3f92d72f7e805b66db1ea0955e113198",
            }
        ),
    }

    response = handler(event, fake_context)
    body = json.loads(response["body"])

    assert response["statusCode"] == 200
    assert body["URL"]["url"] == "https://bucket.s3.amazonaws.com/"
    assert (
        body["URL"]["fields"]["key"]
        == f"raw/database1/v1.0/table1/load_timestamp=20230101T000000Z/{a_uuid}{os.path.splitext(filename)[1]}"
    )


@freeze_time("2023-01-01")
def test_dataproduct_does_not_exist(s3_client, fake_context, region_name, monkeypatch):
    bucket_name = "bucket"
    database = "database1"
    table = "table1"
    filename = "testdata.csv"
    monkeypatch.setattr(boto3, "client", lambda _name: s3_client)
    monkeypatch.setenv("BUCKET_NAME", bucket_name)

    s3_client.create_bucket(
        Bucket=bucket_name,
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )

    event = {
        "pathParameters": {
            "data-product-name": database,
            "table-name": table,
        },
        "body": json.dumps(
            {
                "filename": filename,
                "contentMD5": "3f92d72f7e805b66db1ea0955e113198",
            }
        ),
    }

    response = handler(event, fake_context)
    body = json.loads(response["body"])

    assert response["statusCode"] == 404
    assert (
        body["error"]["message"]
        == "Data product registration relating to database not found."
    )


@freeze_time("2023-01-01")
def test_invalid_file_extension(fake_context):
    database = "database1"
    table = "table1"
    filename = "testdata"

    event = {
        "pathParameters": {
            "data-product-name": database,
            "table-name": table,
        },
        "body": json.dumps(
            {
                "filename": filename,
                "contentMD5": "3f92d72f7e805b66db1ea0955e113198",
            }
        ),
    }

    response = handler(event, fake_context)
    body = json.loads(response["body"])

    assert response["statusCode"] == 400
    assert body["error"]["message"] == "file extension is invalid."


@freeze_time("2023-01-01")
def test_invalid_params(s3_client, fake_context, region_name, monkeypatch):
    bucket_name = "bucket"
    monkeypatch.setattr(boto3, "client", lambda _name: s3_client)
    monkeypatch.setenv("BUCKET_NAME", bucket_name)

    event = {
        "pathParameters": {
            "data-product-name": None,
            "table-name": None,
        },
        "body": json.dumps(
            {
                "filename": None,
                "contentMD5": "3f92d72f7e805b66db1ea0955e113198",
            }
        ),
    }

    response = handler(event, fake_context)
    body = json.loads(response["body"])

    assert response["statusCode"] == 400
    assert (
        body["error"]["message"]
        == "data product name, table name or filename are not convertible to string type."
    )
