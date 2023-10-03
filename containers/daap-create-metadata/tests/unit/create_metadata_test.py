import json
from unittest.mock import patch

import create_metadata


def test_missing_metadata_name_fail(fake_context):
    response = create_metadata.handler(
        {"httpMethod": "POST", "body": """{"metadata": {"domain": "MoJ"}}"""},
        context=fake_context,
    )
    assert response["statusCode"] == 400


def test_existing_metadata_definition_fail(fake_context):
    with patch("create_metadata.DataProductMetadata") as mock_metadata:
        mock_metadata.return_value.metadata_exists = True
        mock_metadata.return_value.valid_metadata = None
        print(mock_metadata.return_value.validate_metadata)
        print(bool(mock_metadata.return_value.validate_metadata))
        response = create_metadata.handler(
            {"httpMethod": "POST", "body": """{"metadata": {"name": "test"}}"""},
            context=fake_context,
        )
        assert response["statusCode"] == 409
        assert (
            json.loads(response["body"])["error"]["message"]
            == f"Data Product test already has a version 1 registered metadata."
        )


def test_metadata_creation_pass(fake_context):
    with patch("create_metadata.DataProductMetadata") as mock_metadata:
        mock_metadata.return_value.metadata_exists = False
        mock_metadata.return_value.valid_metadata = True
        response = create_metadata.handler(
            {"httpMethod": "POST", "body": """{"metadata": {"name": "test"}}"""},
            context=fake_context,
        )
        assert response["statusCode"] == 201


def test_metadata_validation_fail(fake_context):
    with patch("create_metadata.DataProductMetadata") as mock_metadata:
        mock_metadata.return_value.metadata_exists = False
        mock_metadata.return_value.valid_metadata = False
        mock_metadata.return_value.error_traceback = "testing"
        response = create_metadata.handler(
            {"httpMethod": "POST", "body": """{"metadata": {"name": "test"}}"""},
            context=fake_context,
        )
        assert response["statusCode"] == 400
        assert (
            json.loads(response["body"])["error"]["message"]
            == f"Metadata failed validation with error: {mock_metadata.return_value.error_traceback}"
        )
