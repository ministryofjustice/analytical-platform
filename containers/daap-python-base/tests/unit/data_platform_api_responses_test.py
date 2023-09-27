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


def test_response_status_400():
    response = data_platform_api_responses.response_status_400("something went wrong")

    assert response == {
        "statusCode": 400,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": {"message": "something went wrong"}}),
    }


def test_response_status_404():
    response = data_platform_api_responses.response_status_404(
        "something went wrong again"
    )

    assert response == {
        "statusCode": 400,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": {"message": "something went wrong again"}}),
    }


def test_response_status_200():
    response = data_platform_api_responses.response_status_200("success")

    assert response == {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"message": "success"}),
    }
