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
from data_platform_catalogue.client.datahub.datahub_client import DataHubCatalogueClient
from data_platform_catalogue.entities import DataLocation
from data_platform_catalogue.search_types import MultiSelectFilter, ResultType
from datahub.metadata.schema_classes import DatasetPropertiesClass, SchemaMetadataClass

jwt_token = os.environ.get("JWT_TOKEN")
api_url = os.environ.get("API_URL", "")
runs_on_development_server = pytest.mark.skipif("not jwt_token or not api_url")


@runs_on_development_server
def test_upsert_test_hierarchy():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    data_product = DataProductMetadata(
        name="test_data_product",
        description="bla bla",
        version="v1.0.0",
        owner="7804c127-d677-4900-82f9-83517e51bb94",
        email="justice@justice.gov.uk",
        retention_period_in_days=365,
        domain="Sample",
        dpia_required=False,
    )

    table = TableMetadata(
        name="test_table",
        description="bla bla",
        column_details=[
            {"name": "foo", "type": "string", "description": "a"},
            {"name": "bar", "type": "int", "description": "b"},
        ],
        retention_period_in_days=365,
        tags=["test"],
    )

    table_fqn = client.upsert_table(
        metadata=table,
        data_product_metadata=data_product,
        location=DataLocation("test_data_product_v2"),
    )
    assert (
        table_fqn
        == "urn:li:dataset:(urn:li:dataPlatform:glue,test_data_product_v2.test_table,PROD)"
    )

    # Ensure data went through
    assert client.graph.get_aspect(table_fqn, DatasetPropertiesClass)
    assert client.graph.get_aspect(table_fqn, SchemaMetadataClass)


@runs_on_development_server
def test_search():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)
    response = client.search()
    assert response.total_results > 20
    assert len(response.page_results) == 20


@runs_on_development_server
def test_search_for_data_product():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    data_product = DataProductMetadata(
        name="lfdskjflkjflkjsdflksfjds",
        description="lfdskjflkjflkjsdflksfjds",
        version="v1.0.0",
        owner="7804c127-d677-4900-82f9-83517e51bb94",
        email="justice@justice.gov.uk",
        retention_period_in_days=365,
        domain="Sample",
        dpia_required=False,
        tags=["test"],
    )
    client.upsert_data_product(data_product)

    response = client.search(
        query="lfdskjflkjflkjsdflksfjds", result_types=(ResultType.DATA_PRODUCT,)
    )
    assert response.total_results >= 1
    assert response.page_results[0].id == "urn:li:dataProduct:lfdskjflkjflkjsdflksfjds"


@runs_on_development_server
def test_search_by_domain():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    response = client.search(
        filters=[MultiSelectFilter("domains", ["does-not-exist"])],
        result_types=(ResultType.DATA_PRODUCT,),
    )
    assert response.total_results == 0


@runs_on_development_server
def test_domain_facets_are_returned():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    data_product = DataProductMetadata(
        name="lfdskjflkjflkjsdflksfjds",
        description="lfdskjflkjflkjsdflksfjds",
        version="v1.0.0",
        owner="7804c127-d677-4900-82f9-83517e51bb94",
        email="justice@justice.gov.uk",
        retention_period_in_days=365,
        domain="Sample",
        dpia_required=False,
        tags=["test"],
    )
    client.upsert_data_product(data_product)

    response = client.search()
    assert response.facets.options("domains")
    assert client.search_facets().options("domains")


@runs_on_development_server
def test_filter_by_urn():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    data_product = DataProductMetadata(
        name="lfdskjflkjflkjsdflksfjds",
        description="lfdskjflkjflkjsdflksfjds",
        version="v1.0.0",
        owner="7804c127-d677-4900-82f9-83517e51bb94",
        email="justice@justice.gov.uk",
        retention_period_in_days=365,
        domain="Sample",
        dpia_required=False,
        tags=["test"],
    )
    urn = client.upsert_data_product(data_product)

    response = client.search(
        filters=[MultiSelectFilter(filter_name="urn", included_values=[urn])]
    )
    assert response.total_results == 1


@runs_on_development_server
def test_fetch_dataset_belonging_to_data_product():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    data_product = DataProductMetadata(
        name="test_data_product",
        description="bla bla",
        version="v1.0.0",
        owner="7804c127-d677-4900-82f9-83517e51bb94",
        email="justice@justice.gov.uk",
        retention_period_in_days=365,
        domain="Sample",
        dpia_required=False,
    )

    table = TableMetadata(
        name="test_table",
        description="bla bla",
        column_details=[
            {"name": "foo", "type": "string", "description": "a"},
            {"name": "bar", "type": "int", "description": "b"},
        ],
        retention_period_in_days=365,
        tags=["test"],
    )

    urn = client.upsert_table(
        metadata=table,
        data_product_metadata=data_product,
        location=DataLocation("test_data_product_v2"),
    )

    response = client.search(
        filters=[MultiSelectFilter(filter_name="urn", included_values=[urn])]
    )

    assert response.total_results == 1

    metadata = response.page_results[0].metadata
    assert metadata["total_data_products"] == 1
    assert metadata["data_products"][0]["name"] == "test_data_product"
