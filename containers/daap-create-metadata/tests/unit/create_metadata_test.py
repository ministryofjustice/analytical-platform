import json
from http import HTTPMethod, HTTPStatus
from unittest.mock import patch

import create_metadata
import pytest


@pytest.mark.parametrize("body_content", [{"metadata": {"domain": "MoJ"}}])
def test_missing_metadata_name_fail(fake_event, fake_context):
    response = create_metadata.handler(event=fake_event, context=fake_context)

    assert response["statusCode"] == HTTPStatus.BAD_REQUEST


def test_existing_metadata_definition_fail(fake_event, fake_context):
    with patch("create_metadata.DataProductMetadata") as mock_metadata:
        mock_metadata.return_value.metadata_exists = True

        response = create_metadata.handler(event=fake_event, context=fake_context)

        assert response["statusCode"] == HTTPStatus.CONFLICT
        assert (
            json.loads(response["body"])["error"]["message"]
            == "Data Product test_name already has a version 1 registered metadata."
        )


def test_metadata_creation_pass(fake_event, fake_context):
    with patch("create_metadata.DataProductMetadata") as mock_metadata:
        mock_metadata.return_value.exists = False
        mock_metadata.return_value.valid = True
        with patch("create_metadata.DataProductConfig") as mock_key:
            mock_key.return_value.metadata_path.key = "somekey"
            response = create_metadata.handler(event=fake_event, context=fake_context)

            assert response["statusCode"] == HTTPStatus.CREATED


def test_metadata_validation_fail(fake_event, fake_context):
    with patch("create_metadata.DataProductMetadata") as mock_metadata:
        mock_metadata.return_value.exists = False
        mock_metadata.return_value.valid = False
        mock_metadata.return_value.error_traceback = "testing"

        response = create_metadata.handler(event=fake_event, context=fake_context)

        assert response["statusCode"] == HTTPStatus.BAD_REQUEST
        assert (
            json.loads(response["body"])["error"]["message"]
            == f"Metadata failed validation with error: {mock_metadata.return_value.error_traceback}"
        )


@pytest.mark.parametrize("method", [HTTPMethod.GET, HTTPMethod.PUT, HTTPMethod.DELETE])
def test_http_method_fail(fake_event, fake_context, method):
    with patch("create_metadata.DataProductMetadata") as mock_metadata:
        mock_metadata.return_value.exists = False
        mock_metadata.return_value.valid = True

        response = create_metadata.handler(event=fake_event, context=fake_context)

        assert response["statusCode"] == HTTPStatus.METHOD_NOT_ALLOWED
        assert (
            json.loads(response["body"])["error"]["message"]
            == f"Sorry, {method} isn't allowed."
        )
