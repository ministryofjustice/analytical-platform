from query_data import handler


def test_query_athena_with_results(athena_client, fake_context):
    # Mock the Athena client and its methods
    athena_client.return_value = athena_client

    # Mock the start_query_execution method
    athena_client.start_query_execution.return_value = {
        "QueryExecutionId": "fake_query_execution_id"
    }

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

    result = handler(
        {
            "pathParameters": {
                "data-product-name": "abc",
                "table-name": "def",
            }
        },
        fake_context,
        athena_client,
    )

    processed_results = result["body"]

    expected_results = '"| Header1      | Header2      | Header2Longerone |\
\\n| Row 1 Data 1 | Row 1 Data 2 | 20231023T144052Z |\
\\n| Row 2 Data 1 | Row 2 Data 2 | 20231024T144052Z |\
\\n| Row 3 Data 1 | Row 3 Data 2 | 20231025T144052Z |\\n"'

    assert processed_results == expected_results


def test_query_athena_without_results(athena_client, fake_context):
    # Mock the Athena client and its methods
    athena_client.return_value = athena_client

    # Mock the start_query_execution method
    athena_client.start_query_execution.return_value = {
        "QueryExecutionId": "fake_query_execution_id"
    }

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

    result = handler(
        {
            "pathParameters": {
                "data-product-name": "abc",
                "table-name": "def",
            }
        },
        fake_context,
        athena_client,
    )

    processed_results = result["body"]

    expected_results = '"No data to display"'

    assert processed_results == expected_results
