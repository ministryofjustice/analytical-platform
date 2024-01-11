import json

import data_platform_api_responses


def test_format_response_json():
    formatted_response_json = data_platform_api_responses.format_response_json(
        111, {"test": "test"}
    )

    assert formatted_response_json == {
        "statusCode": 111,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"test": "test"}),
    }


def test_format_error_response():
    formatted_response_json = data_platform_api_responses.format_error_response(
        111, {"foo": "bar"}, "message"
    )

    assert formatted_response_json == {
        "statusCode": 111,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": {"message": "message"}}),
    }
