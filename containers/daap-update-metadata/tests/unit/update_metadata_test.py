import json
from http import HTTPStatus

import pytest
from update_metadata import handler


@pytest.fixture
def body_content():
    return {"metadata": {"description": "bar"}}


@pytest.fixture
def fake_event(body_content):
    return {
        "httpMethod": "POST",
        "headers": {"Content-Type": "application/json"},
        "pathParameters": {"data-product-name": "test_p", "table-name": "test_t"},
        "body": json.dumps(body_content),
    }


def test_handler(s3_client, fake_event, fake_context):
    s3_client.put_object(
        Body=json.dumps({"description": "test_p"}),
        Bucket="test",
        Key="test_p/v1.0/metadata.json",
    )

    response = handler(fake_event, fake_context)

    assert response == {
        "body": json.dumps({"version": "v1.1"}),
        "statusCode": HTTPStatus.OK,
        "headers": {"Content-Type": "application/json"},
    }
