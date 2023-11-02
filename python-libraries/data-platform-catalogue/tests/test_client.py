import pytest
from data_platform_catalogue.client import CatalogueClient, ReferencedEntityMissing
from data_platform_catalogue.entities import (
    CatalogueMetadata,
    DataProductMetadata,
    TableMetadata,
)


class TestCatalogueClient:
    def mock_service_response(self, fqn):
        return {
            "fullyQualifiedName": fqn,
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "name": "foo",
            "serviceType": "Glue",
        }

    def mock_database_response(self, fqn):
        return {
            "fullyQualifiedName": fqn,
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            "name": "foo",
            "service": {
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
                "type": "Glue",
            },
        }

    def mock_schema_response(self, fqn):
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

    def mock_table_response(self, fqn):
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

    def mock_user_response(self, fqn):
        return {
            "email": "justice@justice.gov.uk",
            "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
        }

    @pytest.fixture
    def catalogue(self):
        return CatalogueMetadata(
            name="data_platform",
            description="All data products hosted on the data platform",
        )

    @pytest.fixture
    def data_product(self):
        return DataProductMetadata(
            name="my_data_product",
            description="bla bla",
            version="v1.0.0",
            owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
            email="justice@justice.gov.uk",
            retention_period_in_days=365,
            domain="legal-aid",
            dpia_required=False,
            tags=["test"],
        )

    @pytest.fixture
    def table(self):
        return TableMetadata(
            name="my_table",
            description="bla bla",
            column_details=[
                {"name": "foo", "type": "string", "description": "a"},
                {"name": "bar", "type": "int", "description": "b"},
            ],
            retention_period_in_days=365,
        )

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
            "serviceType": "Glue",
            "connection": {"config": {}},
        }
        assert fqn == "some-service"

    def test_create_database(self, client, requests_mock, catalogue):
        requests_mock.put(
            "http://example.com/api/v1/databases",
            json=self.mock_database_response("some-db"),
        )

        fqn = client.create_or_update_database(
            metadata=catalogue, service_fqn="data-platform"
        )
        assert requests_mock.last_request.json() == {
            "name": "data_platform",
            "displayName": None,
            "description": "All data products hosted on the data platform",
            "tags": [],
            "owner": None,
            "service": "data-platform",
            "default": False,
            "retentionPeriod": None,
            "extension": None,
            "sourceUrl": None,
        }
        assert fqn == "some-db"

    def test_create_schema(self, client, requests_mock, data_product):
        requests_mock.put(
            "http://example.com/api/v1/databaseSchemas",
            json=self.mock_schema_response("some-schema"),
        )

        fqn = client.create_or_update_schema(
            metadata=data_product, database_fqn="data-product"
        )
        assert requests_mock.last_request.json() == {
            "name": "my_data_product",
            "displayName": None,
            "description": "bla bla",
            "owner": {
                "deleted": None,
                "description": None,
                "displayName": None,
                "fullyQualifiedName": None,
                "href": None,
                "id": "2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
                "name": None,
                "type": "user",
            },
            "database": "data-product",
            "tags": [
                {
                    "description": None,
                    "href": None,
                    "labelType": "Automated",
                    "source": "Classification",
                    "state": "Confirmed",
                    "tagFQN": "test",
                }
            ],
            "retentionPeriod": "P365D",
            "extension": None,
            "sourceUrl": None,
        }
        assert fqn == "some-schema"

    def test_create_table(self, client, requests_mock, table):
        requests_mock.put(
            "http://example.com/api/v1/tables",
            json=self.mock_table_response("some-table"),
        )

        fqn = client.create_or_update_table(
            metadata=table, schema_fqn="data-platform.data-product.schema"
        )
        assert requests_mock.last_request.json() == {
            "name": "my_table",
            "displayName": None,
            "description": "bla bla",
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
                    "description": "a",
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
                    "description": "b",
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
            "tags": [],
            "viewDefinition": None,
            "retentionPeriod": "P365D",
            "extension": None,
            "sourceUrl": None,
            "fileFormat": None,
        }
        assert fqn == "some-table"

    def test_404_handling(self, client, requests_mock, table):
        requests_mock.put(
            "http://example.com/api/v1/tables",
            status_code=404,
            json={"code": "something", "message": "something"},
        )

        with pytest.raises(ReferencedEntityMissing):
            client.create_or_update_table(
                metadata=table, schema_fqn="data-platform.data-product.schema"
            )

    def test_get_user_id(self, requests_mock, client):
        requests_mock.get(
            "http://example.com/api/v1/users/name/justice",
            json={
                "email": "justice@justice.gov.uk",
                "name": "justice",
                "id": "39b855e3-84a5-491e-b9a5-c411e626e340",
            },
        )
        user_id = client.get_user_id("justice@justice.gov.uk")

        assert "39b855e3-84a5-491e-b9a5-c411e626e340" in str(user_id)
