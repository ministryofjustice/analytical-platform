import json
from unittest.mock import patch

import pytest
from preview_data import handler

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


@pytest.fixture
def metadata_content(s3_client):
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


def fake_event(body_content, table_name="test_t"):
    return {
        "httpMethod": "PUT",
        "headers": {"Content-Type": "application/json"},
        "pathParameters": {"data-product-name": "test_p", "table-name": table_name},
        "body": json.dumps(body_content),
    }


def test_query_athena_with_results(
    metadata_content, body_content, fake_context, athena_client
):
    # Mock the get_query_results method
    athena_client.get_query_results.return_value = {
        "ResultSet": {
            "Rows": [
                {
                    "Data": [
                        {"VarCharValue": "Header1"},
                        {"VarCharValue": "Header2"},
                        {"VarCharValue": "Header2Longerone"},
                    ]
                },
                {
                    "Data": [
                        {"VarCharValue": "Row 1 Data 1"},
                        {"VarCharValue": "Row 1 Data 2"},
                        {"VarCharValue": "20231023T144052Z"},
                    ]
                },
                {
                    "Data": [
                        {"VarCharValue": "Row 2 Data 1"},
                        {"VarCharValue": "Row 2 Data 2"},
                        {"VarCharValue": "20231024T144052Z"},
                    ]
                },
                {
                    "Data": [
                        {"VarCharValue": "Row 3 Data 1"},
                        {"VarCharValue": "Row 3 Data 2"},
                        {"VarCharValue": "20231025T144052Z"},
                    ]
                },
            ]
        }
    }

    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        result = handler(fake_event(body_content), fake_context, athena_client)

    processed_results = result["body"]

    expected_results = "| Header1      | Header2      | Header2Longerone |\
\n| Row 1 Data 1 | Row 1 Data 2 | 20231023T144052Z |\
\n| Row 2 Data 1 | Row 2 Data 2 | 20231024T144052Z |\
\n| Row 3 Data 1 | Row 3 Data 2 | 20231025T144052Z |\n"

    assert processed_results == expected_results


def test_query_athena_without_results(
    metadata_content, body_content, fake_context, athena_client
):
    # Mock the get_query_results method
    athena_client.get_query_results.return_value = {
        "ResultSet": {
            "Rows": [
                {
                    "Data": [
                        {"VarCharValue": "Header1"},
                        {"VarCharValue": "Header2"},
                        {"VarCharValue": "Header2Longerone"},
                    ]
                }
                # No Data row
            ]
        }
    }

    with patch("data_platform_paths.get_latest_version", lambda _: "v1.0"):
        result = handler(fake_event(body_content), fake_context, athena_client)

    processed_results = result["body"]

    expected_results = "No data to display"

    assert processed_results == expected_results
