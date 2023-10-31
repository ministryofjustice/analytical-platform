import json
from http import HTTPStatus

import pytest
from update_metadata import handler


@pytest.fixture
def body_content():
    return {"metadata": {"description": "bar"}}


def fake_event(body_content):
    return {
        "httpMethod": "POST",
        "headers": {"Content-Type": "application/json"},
        "pathParameters": {"data-product-name": "test_p", "table-name": "test_t"},
        "body": json.dumps(body_content),
    }


def test_success(s3_client, body_content, fake_context):
    s3_client.put_object(
        Body=json.dumps({"name": "foo", "description": "test_p"}),
        Bucket="test",
        Key="test_p/v1.0/metadata.json",
    )

    response = handler(fake_event(body_content), fake_context)

    assert response == {
        "body": json.dumps({"version": "v1.1"}),
        "statusCode": HTTPStatus.OK,
        "headers": {"Content-Type": "application/json"},
    }


def test_invalid_body(s3_client, fake_context):
    s3_client.put_object(
        Body=json.dumps({"name": "foo", "description": "test_p"}),
        Bucket="test",
        Key="test_p/v1.0/metadata.json",
    )

    response = handler(fake_event({}), fake_context)

    assert response == {
        "body": json.dumps(
            {"error": {"message": "Body JSON must contain a metadata object"}}
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

    response = handler(fake_event({"metadata": {"name": "abc"}}), fake_context)

    assert response == {
        "body": json.dumps({"error": {"message": "Update not allowed"}}),
        "statusCode": HTTPStatus.BAD_REQUEST,
        "headers": {"Content-Type": "application/json"},
    }


def test_invalid_data_product(s3_client, fake_context):
    response = handler(
        fake_event({"metadata": {"name": "does-not-exist"}}), fake_context
    )

    assert response == {
        "body": json.dumps({"error": {"message": "Update not allowed"}}),
        "statusCode": HTTPStatus.BAD_REQUEST,
        "headers": {"Content-Type": "application/json"},
    }
