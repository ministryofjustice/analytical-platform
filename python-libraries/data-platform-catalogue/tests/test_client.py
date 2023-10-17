import pytest
from data_platform_catalogue.client import CatalogueClient


class TestCatalogueClient:
    def mock_service_response(self, fqn):
        return {
            "fullyQualifiedName": fqn,
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "name": "foo",
            "serviceType": "CustomDatabase",
        }

    def mock_database_response(self, fqn):
        return {
            "fullyQualifiedName": fqn,
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "name": "foo",
            "service": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "CustomDatabase",
            },
        }

    def mock_schema_response(self, fqn):
        return {
            "fullyQualifiedName": fqn,
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "name": "foo",
            "service": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "CustomDatabase",
            },
            "database": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "",
            },
        }

    def mock_table_response(self, fqn):
        return {
            "fullyQualifiedName": "some-table",
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "name": "foo",
            "service": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "CustomDatabase",
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

    @pytest.fixture
    def client(self, requests_mock):
        requests_mock.get(
            "http://example.com/api/v1/system/version",
            json={"version": "1.1.7.0", "revision": "1", "timestamp": 0},
        )

        return CatalogueClient(jwt_token="abc", api_uri="http://example.com/api")

    def test_create_service(self, client, requests_mock):
        requests_mock.put(
            "http://example.com/api/v1/services/databaseServices",
            json=self.mock_service_response("some-service"),
        )

        fqn = client.create_or_update_database_service()

        assert requests_mock.last_request.json() == {
            "name": "data-platform",
            "displayName": "Data platform",
            "description": None,
            "tags": None,
            "serviceType": "CustomDatabase",
            "connection": {
                "config": {
                    "type": "CustomDatabase",
                    "sourcePythonClass": None,
                    "connectionOptions": None,
                }
            },
            "owner": None,
        }
        assert fqn == "some-service"

    def test_create_database(self, client, requests_mock):
        requests_mock.put(
            "http://example.com/api/v1/databases",
            json=self.mock_database_response("some-db"),
        )

        fqn = client.create_or_update_database(
            name="data-product", service_fqn="data-platform"
        )
        assert requests_mock.last_request.json() == {
            "name": "data-product",
            "displayName": None,
            "description": None,
            "tags": None,
            "owner": None,
            "service": "data-platform",
            "default": False,
            "retentionPeriod": None,
            "extension": None,
            "sourceUrl": None,
        }
        assert fqn == "some-db"

    def test_create_schema(self, client, requests_mock):
        requests_mock.put(
            "http://example.com/api/v1/databaseSchemas",
            json=self.mock_schema_response("some-schema"),
        )

        fqn = client.create_or_update_schema(name="schema", database_fqn="data-product")
        assert requests_mock.last_request.json() == {
            "name": "schema",
            "displayName": None,
            "description": None,
            "owner": None,
            "database": "data-product",
            "tags": None,
            "retentionPeriod": None,
            "extension": None,
            "sourceUrl": None,
        }
        assert fqn == "some-schema"

    def test_create_table(self, client, requests_mock):
        requests_mock.put(
            "http://example.com/api/v1/tables",
            json=self.mock_table_response("some-table"),
        )

        fqn = client.create_or_update_table(
            name="table",
            schema_fqn="data-platform.data-product.schema",
            column_types={"foo": "string", "bar": "int"},
        )
        assert requests_mock.last_request.json() == {
            "name": "table",
            "displayName": None,
            "description": None,
            "tableType": None,
            "columns": [
                {
                    "name": "foo",
                    "displayName": None,
                    "dataType": "STRING",
                    "arrayDataType": None,
                    "dataLength": None,
                    "precision": None,
                    "scale": None,
                    "dataTypeDisplay": None,
                    "description": None,
                    "fullyQualifiedName": None,
                    "tags": None,
                    "constraint": None,
                    "ordinalPosition": None,
                    "jsonSchema": None,
                    "children": None,
                    "customMetrics": None,
                    "profile": None,
                },
                {
                    "name": "bar",
                    "displayName": None,
                    "dataType": "INT",
                    "arrayDataType": None,
                    "dataLength": None,
                    "precision": None,
                    "scale": None,
                    "dataTypeDisplay": None,
                    "description": None,
                    "fullyQualifiedName": None,
                    "tags": None,
                    "constraint": None,
                    "ordinalPosition": None,
                    "jsonSchema": None,
                    "children": None,
                    "customMetrics": None,
                    "profile": None,
                },
            ],
            "tableConstraints": None,
            "tablePartition": None,
            "tableProfilerConfig": None,
            "owner": None,
            "databaseSchema": "data-platform.data-product.schema",
            "tags": None,
            "viewDefinition": None,
            "retentionPeriod": None,
            "extension": None,
            "sourceUrl": None,
            "fileFormat": None,
        }
        assert fqn == "some-table"
