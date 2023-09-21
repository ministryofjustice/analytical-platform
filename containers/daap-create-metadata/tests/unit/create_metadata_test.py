import create_metadata
from unittest.mock import patch
import json


def test_missing_metadata_name_fail(fake_context):
    response = create_metadata.handler(
        {"body": str("""{"metadata": {"domain": "MoJ"}}""")}, context=fake_context
    )
    assert response["statusCode"] == 400


def test_existing_metadata_definition_fail(fake_context):
    with patch("create_metadata.DataProductMetadata") as mock_metadata:
        mock_metadata.return_value.metadata_exists = True
        response = create_metadata.handler(
            {"body": str("""{"metadata": {"name": "test"}}""")}, context=fake_context
        )
        assert response["statusCode"] == 400
        assert (
            json.loads(response["body"])["message"]
            == "Your data product already has a version 1 registered metadata."
        )


def test_metadata_creation_pass(fake_context):
    with patch("create_metadata.DataProductMetadata") as mock_metadata:
        mock_metadata.return_value.metadata_exists = False
        mock_metadata.return_value.valid_metadata = True
        response = create_metadata.handler(
            {"body": str("""{"metadata": {"name": "test"}}""")}, context=fake_context
        )
        assert response["statusCode"] == 200


def test_metadata_validation_fail(fake_context):
    with patch("create_metadata.DataProductMetadata") as mock_metadata:
        mock_metadata.return_value.metadata_exists = False
        mock_metadata.return_value.valid_metadata = False
        mock_metadata.return_value.error_traceback = "testing"
        response = create_metadata.handler(
            {"body": str("""{"metadata": {"name": "test"}}""")}, context=fake_context
        )
        assert response["statusCode"] == 400
        assert (
            json.loads(response["body"])["message"]
            == "Your metadata failed validation with this error: testing"
        )
