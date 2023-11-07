from unittest.mock import patch

import pytest
from data_platform_catalogue import CatalogueClient, CatalogueError
from push_to_catalogue import handler


def mock_service_response(fqn):
    return {
        "fullyQualifiedName": fqn,
        "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
        "name": "foo",
        "serviceType": "Glue",
    }


def mock_database_response(fqn):
    return {
        "fullyQualifiedName": fqn,
        "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
        "name": "foo",
        "service": {
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "type": "Glue",
        },
    }


def mock_schema_response(fqn):
    return {
        "fullyQualifiedName": fqn,
        "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
        "name": "foo",
        "service": {
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "type": "Glue",
        },
        "database": {
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "type": "",
        },
    }


def mock_table_response(fqn):
    return {
        "fullyQualifiedName": "some-table",
        "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
        "name": "foo",
        "service": {
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "type": "Glue",
        },
        "database": {
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "type": "",
        },
        "databaseSchema": {
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "type": "",
        },
        "columns": [],
    }


def mock_user_response():
    return {
        "email": "justice@justice.gov.uk",
        "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
    }


@pytest.fixture
def client(requests_mock):
    requests_mock.get(
        "http://example.com/api/v1/system/version",
        json={"version": "1.1.7.0", "revision": "1", "timestamp": 0},
    )

    return CatalogueClient(jwt_token="abc", api_uri="http://example.com/api")


def test_successful_request_data_product(secrets_client, fake_context):
    metadata = {
        "name": "foo",
        "description": "testing",
        "domain": "MoJ",
        "dataProductOwner": "matthew.laverty@justice.gov.uk",
        "dataProductOwnerDisplayName": "matt laverty",
        "email": "matthew.laverty@justice.gov.uk",
        "status": "draft",
        "dpiaRequired": False,
        "retentionPeriod": 0,
    }

    secrets_client.create_secret(
        Name="test",
        SecretString='{"token":"abc"}',
    )

    with patch("push_to_catalogue.CatalogueClient") as mock_client:
        mock_client.return_value.get_user_id.return_value = (
            "39b855e3-84a5-491e-b9a5-c411e626e340"
        )
        mock_client.return_value.create_or_update_schema.return_value = (
            "data_plaform.data_platform.foo"
        )

        response = handler(
            event={
                "data_product_name": "foo",
                "metadata": metadata,
                "version": "v1.0",
                "table_name": None,
            },
            context=fake_context,
        )

        assert response == {
            "catalogue_message": "data_plaform.data_platform.foo pushed to catalogue"
        }


def test_unsuccessful_request_data_product(secrets_client, fake_context):
    metadata = {
        "name": "foo2",
        "description": "testing",
        "domain": "MoJ",
        "dataProductOwner": "matthew.laverty@justice.gov.uk",
        "dataProductOwnerDisplayName": "matt laverty",
        "email": "matthew.laverty@justice.gov.uk",
        "status": "draft",
        "dpiaRequired": False,
        "retentionPeriod": 0,
    }

    secrets_client.create_secret(
        Name="test",
        SecretString='{"token":"abc"}',
    )

    with patch("push_to_catalogue.CatalogueClient") as mock_client:
        mock_client.return_value.get_user_id.return_value = (
            "39b855e3-84a5-491e-b9a5-c411e626e340"
        )
        mock_client.return_value.create_or_update_schema.side_effect = CatalogueError
        response = handler(
            event={
                "data_product_name": "foo2",
                "metadata": metadata,
                "version": "v1.0",
                "table_name": None,
            },
            context=fake_context,
        )

        assert response == {"catalogue_error": "foo2 failed push to catalogue"}


def test_successful_request_table(secrets_client, fake_context):
    metadata = {
        "tableDescription": "testing testing",
        "columns": [{"name": "col1", "type": "string", "description": "test"}],
    }
    secrets_client.create_secret(
        Name="test",
        SecretString='{"token":"abc"}',
    )

    with patch("push_to_catalogue.CatalogueClient") as mock_client:
        mock_client.return_value.create_or_update_table.return_value = (
            "data_plaform.data_platform.foo.table"
        )

        response = handler(
            event={
                "data_product_name": "foo",
                "metadata": metadata,
                "version": "v1.0",
                "table_name": "table",
            },
            context=fake_context,
        )

        assert response == {
            "catalogue_message": "data_plaform.data_platform.foo.table pushed to catalogue"
        }


def test_unsuccessful_request_table(secrets_client, fake_context):
    metadata = {
        "tableDescription": "testing testing",
        "columns": [{"name": "col1", "type": "string", "description": "test"}],
    }
    secrets_client.create_secret(
        Name="test",
        SecretString='{"token":"abc"}',
    )

    with patch("push_to_catalogue.CatalogueClient") as mock_client:
        mock_client.return_value.create_or_update_table.side_effect = CatalogueError

        response = handler(
            event={
                "data_product_name": "foo",
                "metadata": metadata,
                "version": "v1.0",
                "table_name": "table",
            },
            context=fake_context,
        )

        assert response == {"catalogue_error": "foo.table failed push to catalogue"}
