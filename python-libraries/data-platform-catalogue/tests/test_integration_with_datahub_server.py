"""
Integration test that runs against a DataHub server

Run with:
export API_URL='https://catalogue.apps-tools.development.data-platform.service.justice.gov.uk/api'
export JWT_TOKEN=******
poetry run pytest tests/test_integration_with_datahub_server.py
"""

import os
import time
from datetime import datetime

import pytest
from data_platform_catalogue import DataProductMetadata, TableMetadata
from data_platform_catalogue.client.datahub.datahub_client import DataHubCatalogueClient
from data_platform_catalogue.entities import DataLocation, DataProductStatus
from data_platform_catalogue.search_types import MultiSelectFilter, ResultType
from datahub.metadata.schema_classes import DatasetPropertiesClass, SchemaMetadataClass

jwt_token = os.environ.get("JWT_TOKEN")
api_url = os.environ.get("API_URL", "")
runs_on_development_server = pytest.mark.skipif("not jwt_token or not api_url")


@runs_on_development_server
def test_upsert_test_hierarchy():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    data_product = DataProductMetadata(
        name="my_data_product",
        description="bla bla",
        version="v1.0.0",
        owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
        owner_display_name="April Gonzalez",
        maintainer="j.shelvey@digital.justice.gov.uk",
        maintainer_display_name="Jonjo Shelvey",
        email="justice@justice.gov.uk",
        status=DataProductStatus.DRAFT.name,
        retention_period_in_days=365,
        domain="LAA",
        subdomain="Legal Aid",
        dpia_required=False,
        dpia_location=None,
        last_updated=datetime(2020, 5, 17),
        creation_date=datetime(2020, 5, 17),
        s3_location="s3://databucket/",
        tags=["test"],
    )

    table = TableMetadata(
        name="test_table",
        description="bla bla",
        column_details=[
            {"name": "foo", "type": "string", "description": "a"},
            {"name": "bar", "type": "int", "description": "b"},
        ],
        retention_period_in_days=365,
        source_dataset_name="my_source_table",
        where_to_access_dataset="s3://databucket/folder",
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

    dataset_properties = client.graph.get_aspect(
        table_fqn, aspect_type=DatasetPropertiesClass
    )
    # check properties been loaded to datahub dataset
    assert dataset_properties.description == table.description
    assert dataset_properties.qualifiedName == f"test_data_product_v2.{table.name}"
    assert dataset_properties.name == table.name
    assert (
        dataset_properties.customProperties["sourceDatasetName"]
        == table.source_dataset_name
    )
    assert (
        dataset_properties.customProperties["whereToAccessDataset"]
        == table.where_to_access_dataset
    )


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
        name="my_data_product",
        description="bla bla",
        version="v1.0.0",
        owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
        owner_display_name="April Gonzalez",
        maintainer="j.shelvey@digital.justice.gov.uk",
        maintainer_display_name="Jonjo Shelvey",
        email="justice@justice.gov.uk",
        status=DataProductStatus.DRAFT.name,
        retention_period_in_days=365,
        domain="LAA",
        subdomain="Legal Aid",
        dpia_required=False,
        dpia_location=None,
        last_updated=datetime(2020, 5, 17),
        creation_date=datetime(2020, 5, 17),
        s3_location="s3://databucket/",
        tags=["test"],
    )
    client.upsert_data_product(data_product)

    response = client.search(
        query="my_data_product", result_types=(ResultType.DATA_PRODUCT,)
    )
    assert response.total_results >= 1
    assert response.page_results[0].id == "urn:li:dataProduct:my_data_product"


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
        name="my_data_product",
        description="bla bla",
        version="v1.0.0",
        owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
        owner_display_name="April Gonzalez",
        maintainer="j.shelvey@digital.justice.gov.uk",
        maintainer_display_name="Jonjo Shelvey",
        email="justice@justice.gov.uk",
        status=DataProductStatus.DRAFT.name,
        retention_period_in_days=365,
        domain="LAA",
        subdomain="Legal Aid",
        dpia_required=False,
        dpia_location=None,
        last_updated=datetime(2020, 5, 17),
        creation_date=datetime(2020, 5, 17),
        s3_location="s3://databucket/",
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
        name="my_data_product",
        description="bla bla",
        version="v1.0.0",
        owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
        owner_display_name="April Gonzalez",
        maintainer="j.shelvey@digital.justice.gov.uk",
        maintainer_display_name="Jonjo Shelvey",
        email="justice@justice.gov.uk",
        status=DataProductStatus.DRAFT.name,
        retention_period_in_days=365,
        domain="LAA",
        subdomain="Legal Aid",
        dpia_required=False,
        dpia_location=None,
        last_updated=datetime(2020, 5, 17),
        creation_date=datetime(2020, 5, 17),
        s3_location="s3://databucket/",
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
        name="my_data_product",
        description="bla bla",
        version="v1.0.0",
        owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
        owner_display_name="April Gonzalez",
        maintainer="j.shelvey@digital.justice.gov.uk",
        maintainer_display_name="Jonjo Shelvey",
        email="justice@justice.gov.uk",
        status=DataProductStatus.DRAFT.name,
        retention_period_in_days=365,
        domain="LAA",
        subdomain="Legal Aid",
        dpia_required=False,
        dpia_location=None,
        last_updated=datetime(2020, 5, 17),
        creation_date=datetime(2020, 5, 17),
        s3_location="s3://databucket/",
        tags=["test"],
    )

    table = TableMetadata(
        name="test_table",
        description="bla bla",
        column_details=[
            {"name": "foo", "type": "string", "description": "a"},
            {"name": "bar", "type": "int", "description": "b"},
        ],
        retention_period_in_days=365,
        source_dataset_name="my_source_table",
        where_to_access_dataset="s3://databucket/folder",
        tags=["test"],
    )

    urn = client.upsert_table(
        metadata=table,
        data_product_metadata=data_product,
        location=DataLocation("test_data_product_v2"),
    )
    # Introduce sleep to combat race conditions with table association
    time.sleep(2)

    response = client.search(
        filters=[MultiSelectFilter(filter_name="urn", included_values=[urn])]
    )
    assert response.total_results == 1

    metadata = response.page_results[0].metadata
    assert metadata["total_data_products"] == 1
    assert metadata["data_products"][0]["name"] == "my_data_product"


@runs_on_development_server
def test_paginated_search_results_unique():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)
    results1 = client.search(page="1").page_results
    results2 = client.search(page="2").page_results
    assert not any(x in results1 for x in results2)


@runs_on_development_server
def test_list_data_product_assets_returns():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)
    assets = client.list_data_product_assets(
        urn="urn:li:dataProduct:my_data_product", count=20
    )
    assert assets


@runs_on_development_server
def test_get_glossary_terms_returns():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)
    assets = client.get_glossary_terms(count=20)
    assert assets


@runs_on_development_server
def test_get_dataset():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)
    table = client.get_table_details(
        urn="urn:li:dataset:(urn:li:dataPlatform:glue,nomis.agency_release_beds,PROD)"
    )
    assert table
