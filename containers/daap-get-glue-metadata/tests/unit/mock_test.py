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


def test_success_case(glue_client, monkeypatch, fake_context):
    test_database_name = "test_db"
    test_table_name = "test_table"
    s3_location = f"s3://my-bucket/{test_database_name}/{test_table_name}"
    table_input = glue_table_input(test_table_name, s3_location)
    glue_client.create_database(DatabaseInput={"Name": test_database_name})
    glue_client.create_table(DatabaseName=test_database_name, TableInput=table_input)

    # Use the mock client in the lambda, not a real one
    monkeypatch.setattr(boto3, "client", lambda _name: glue_client)

    event = {
        "queryStringParameters": {
            "database": test_database_name,
            "table": test_table_name,
        },
    }
    test_response = get_glue_metadata.handler(event, context=fake_context)
    body = json.loads(test_response["body"])

    assert test_response["statusCode"] == 200
    assert body["Table"].items() >= table_input.items()

    expected_metadata = {"HTTPStatusCode", "HTTPHeaders", "RetryAttempts"}
    assert body["ResponseMetadata"].keys() == expected_metadata
