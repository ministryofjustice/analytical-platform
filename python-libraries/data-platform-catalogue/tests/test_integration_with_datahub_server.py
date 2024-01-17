"""
Integration test that runs against a DataHub server

Run with:
export API_URL='https://catalogue.apps-tools.development.data-platform.service.justice.gov.uk/api'
export JWT_TOKEN=******
poetry run pytest tests/test_integration_with_server.py
"""

import os

import pytest
from data_platform_catalogue import DataProductMetadata, TableMetadata
from data_platform_catalogue.client import DataHubCatalogueClient
from datahub.metadata.schema_classes import DatasetPropertiesClass, SchemaMetadataClass

jwt_token = os.environ.get("JWT_TOKEN")
api_url = os.environ.get("API_URL", "")
runs_on_development_server = pytest.mark.skipif("not jwt_token or not api_url")


@runs_on_development_server
def test_upsert_test_hierarchy():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    data_product = DataProductMetadata(
        name="my_data_product2",
        description="bla bla",
        version="v1.0.0",
        owner="7804c127-d677-4900-82f9-83517e51bb94",
        email="justice@justice.gov.uk",
        retention_period_in_days=365,
        domain="Sample",
        dpia_required=False,
        tags=["test"],
    )

    table = TableMetadata(
        name="my_table2",
        description="bla bla",
        column_details=[
            {"name": "foo", "type": "string", "description": "a"},
            {"name": "bar", "type": "int", "description": "b"},
        ],
        retention_period_in_days=365,
    )

    table_fqn = client.upsert_table(
        metadata=table,
        data_product_metadata=data_product,
        platform="glue",
    )
    assert table_fqn == "urn:li:dataset:(urn:li:dataPlatform:glue,my_table2,PROD)"

    # Ensure data went through
    assert client.graph.get_aspect(table_fqn, DatasetPropertiesClass)
    assert client.graph.get_aspect(table_fqn, SchemaMetadataClass)
