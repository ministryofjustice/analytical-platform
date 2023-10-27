import json
from http import HTTPStatus
from unittest.mock import patch

import pytest
from update_schema import handler

test_glue_table_input = {
    "DatabaseName": "test_p",
    "TableInput": {
        "Description": "table has schema to pass test",
        "Name": "test_t",
        "Owner": "matthew.laverty@justice.gov.uk",
        "Retention": 3000,
        "Parameters": {"classification": "csv", "skip.header.line.count": "1"},
        "PartitionKeys": [],
        "StorageDescriptor": {
            "BucketColumns": [],
            "Columns": [{"Name": "col1", "Type": "int", "Comment": "test"}],
            "Compressed": False,
            "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
            "Location": "",
            "NumberOfBuckets": -1,
            "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
            "Parameters": {},
            "SerdeInfo": {
                "Parameters": {"escape.delim": "\\", "field.delim": ","},
                "SerializationLibrary": "org.apache.hadoop.hive.serde2.OpenCSVSerde",
            },
            "SortColumns": [],
            "StoredAsSubDirectories": False,
        },
        "TableType": "EXTERNAL_TABLE",
    },
}


@pytest.fixture
def body_content():
    return {
        "schema": {
            "tableDescription": "test table",
            "columns": [
                {"name": "col1", "type": "int", "description": "test"},
                {"name": "col2", "type": "int", "description": "test"},
            ],
        }
    }


def fake_event(body_content, table_name="test_t"):
    return {
        "httpMethod": "PUT",
        "headers": {"Content-Type": "application/json"},
        "pathParameters": {"data-product-name": "test_p", "table-name": table_name},
        "body": json.dumps(body_content),
    }


def test_success(s3_client, body_content, fake_context):
    s3_client.put_object(
        Body=json.dumps(
            {
                "name": "test_p",
                "description": "test_p",
                "dataProductOwner": "me@justice.gov.uk",
                "dataProductOwnerDisplayName": "me",
                "email": "me@justice.gov.uk",
                "status": "draft",
                "retentionPeriod": 3000,
                "dpiaRequired": False,
                "schemas": ["test_p"],
            }
        ),
        Bucket="test",
        Key="test_p/v1.0/metadata.json",
    )
    s3_client.put_object(
        Body=json.dumps(test_glue_table_input),
        Bucket="test",
        Key="test_p/v1.0/test_t/schema.json",
    )
    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        response = handler(fake_event(body_content), fake_context)

    assert response == {
        "body": json.dumps(
            {
                "version": "v1.1",
                "changes": {
                    "test_t": {
                        "columns": {
                            "removed_columns": None,
                            "added_columns": ["col2"],
                            "types_changed": None,
                            "descriptions_changed": None,
                        },
                        "non_column_fields": ["tableDescription"],
                    }
                },
            }
        ),
        "statusCode": HTTPStatus.OK,
        "headers": {"Content-Type": "application/json"},
    }


def test_invalid_body(s3_client, fake_context):
    s3_client.put_object(
        Body=json.dumps({"name": "foo", "description": "test_p"}),
        Bucket="test",
        Key="test_p/v1.0/metadata.json",
    )
    s3_client.put_object(
        Body=json.dumps(
            {
                "schema": {
                    "tableDescription": "test table",
                    "columns": [{"name": "col1", "type": "int", "description": "test"}],
                }
            }
        ),
        Bucket="test",
        Key="test_p/v1.0/test_t/schema.json",
    )

    response = handler(fake_event({}), fake_context)

    assert response == {
        "body": json.dumps(
            {"error": {"message": "Body JSON must contain a schema object"}}
        ),
        "statusCode": HTTPStatus.BAD_REQUEST,
        "headers": {"Content-Type": "application/json"},
    }


def test_invalid_update(s3_client, fake_context):
    s3_client.put_object(
        Body=json.dumps({"name": "foo", "description": "test_p"}),
        Bucket="test",
        Key="test_p/v1.0/metadata.json",
    )
    s3_client.put_object(
        Body=json.dumps(
            {
                "schema": {
                    "tableDescription": "test table",
                    "columns": [{"name": "col1", "type": "int", "description": "test"}],
                }
            }
        ),
        Bucket="test",
        Key="test_p/v1.0/test_t/schema.json",
    )

    with patch("versioning.DataProductSchema") as mock_schema:
        mock_schema.return_value.load().valid = False
        response = handler(fake_event({"schema": {"name": "abc"}}), fake_context)

    assert response == {
        "body": json.dumps({"error": {"message": "Update not allowed"}}),
        "statusCode": HTTPStatus.BAD_REQUEST,
        "headers": {"Content-Type": "application/json"},
    }


def test_schema_does_not_exist(s3_client, fake_context):
    response = handler(
        fake_event({"schema": {"tableDescription": "does-not-exist"}}, "nope"),
        fake_context,
    )

    assert response == {
        "body": json.dumps(
            {
                "error": {
                    "message": "Schema does not exists. Cannot update schema without a previous version"
                }
            }
        ),
        "statusCode": HTTPStatus.BAD_REQUEST,
        "headers": {"Content-Type": "application/json"},
    }
