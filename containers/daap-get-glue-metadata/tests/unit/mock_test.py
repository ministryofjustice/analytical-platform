import json

import boto3
import get_glue_metadata


def glue_table_input(name, location):
    """
    Fake a table input for a Glue catalogue
    """
    return {
        "Name": name,
        "Owner": "a_fake_owner",
        "Parameters": {
            "EXTERNAL": "TRUE",
        },
        "Retention": 0,
        "StorageDescriptor": {
            "Location": location,
            "BucketColumns": [],
            "Compressed": False,
            "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
            "NumberOfBuckets": -1,
            "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
            "Parameters": {},
            "SerdeInfo": {
                "Parameters": {"serialization.format": "1"},
                "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe",
            },
            "SkewedInfo": {
                "SkewedColumnNames": [],
                "SkewedColumnValueLocationMaps": {},
                "SkewedColumnValues": [],
            },
            "SortColumns": [],
            "StoredAsSubDirectories": False,
        },
        "TableType": "EXTERNAL_TABLE",
    }


def create_table(glue_client, table_name, database_name):
    s3_location = f"s3://my-bucket/{database_name}/{table_name}"
    table_input = glue_table_input(table_name, s3_location)
    glue_client.create_database(DatabaseInput={"Name": database_name})
    glue_client.create_table(DatabaseName=database_name, TableInput=table_input)
    return table_input


def test_success_case(glue_client, monkeypatch, fake_context):
    test_database_name = "test_db"
    test_table_name = "test_table"
    table_input = create_table(
        glue_client=glue_client,
        database_name=test_database_name,
        table_name=test_table_name,
    )

    # Use the mock client in the lambda, not a real one
    monkeypatch.setattr(boto3, "client", lambda _name: glue_client)

    test_response = get_glue_metadata.handler(
        {
            "queryStringParameters": {
                "database": test_database_name,
                "table": test_table_name,
            },
        },
        context=fake_context,
    )
    body = json.loads(test_response["body"])

    assert test_response["statusCode"] == 200
    assert body["Table"].items() >= table_input.items()

    expected_metadata = {"HTTPStatusCode", "HTTPHeaders", "RetryAttempts"}
    assert body["ResponseMetadata"].keys() == expected_metadata


def test_table_does_not_exist(glue_client, monkeypatch, fake_context):
    # Use the mock client in the lambda, not a real one
    monkeypatch.setattr(boto3, "client", lambda _name: glue_client)

    test_response = get_glue_metadata.handler(
        {
            "queryStringParameters": {
                "database": "some-database",
                "table": "some-table",
            },
        },
        context=fake_context,
    )
    body = json.loads(test_response["body"])

    assert test_response["statusCode"] == 404
    assert "message" in body["error"]


def test_invalid_request(fake_context):
    test_response = get_glue_metadata.handler(
        {
            "queryStringParameters": {},
        },
        context=fake_context,
    )
    body = json.loads(test_response["body"])

    assert test_response["statusCode"] == 400
    assert "message" in body["error"]
