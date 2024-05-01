"""
Integration test that runs against a DataHub server

Run with:
export API_URL='https://catalogue.apps-tools.development.data-platform.service.justice.gov.uk/api'
export JWT_TOKEN=******
poetry run pytest tests/test_integration_with_datahub_server.py
"""

import os
import time
from datetime import datetime, timezone

import pytest
from data_platform_catalogue.client.datahub_client import DataHubCatalogueClient
from data_platform_catalogue.entities import (
    AccessInformation,
    Column,
    ColumnRef,
    CustomEntityProperties,
    Database,
    DataSummary,
    DomainRef,
    EntityRef,
    Governance,
    OwnerRef,
    RelationshipType,
    Table,
    TagRef,
    UsageRestrictions,
)
from data_platform_catalogue.search_types import MultiSelectFilter, ResultType

jwt_token = os.environ.get("JWT_TOKEN")
api_url = os.environ.get("API_URL", "")
runs_on_development_server = pytest.mark.skipif("not jwt_token or not api_url")


@runs_on_development_server
def test_search():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)
    response = client.search()
    assert response.total_results > 20
    assert len(response.page_results) == 20


@runs_on_development_server
def test_search_by_domain():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    response = client.search(
        filters=[MultiSelectFilter("domains", ["does-not-exist"])],
        result_types=(ResultType.TABLE,),
    )
    assert response.total_results == 0


@runs_on_development_server
def test_domain_facets_are_returned():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    database = Database(
        name="my_database",
        description="little test db",
        governance=Governance(
            data_owner=OwnerRef(
                urn="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
                display_name="April Gonzalez",
                email="abc@digital.justice.gov.uk",
            ),
            data_stewards=[
                OwnerRef(
                    urn="abc",
                    display_name="Jonjo Shelvey",
                    email="j.shelvey@digital.justice.gov.uk",
                )
            ],
        ),
        domain=DomainRef(urn="LAA", display_name="LAA"),
        last_modified=datetime(2020, 5, 17),
        creation_date=datetime(2020, 5, 17),
        access_information=AccessInformation(
            s3_location="s3://databucket/",
        ),
        tags=[TagRef(urn="test", display_name="test")],
        platform=EntityRef(urn="urn:li:dataPlatform:athena", display_name="athena"),
        custom_properties=CustomEntityProperties(
            usage_restrictions=UsageRestrictions(
                dpia_required=False,
                dpia_location=None,
            ),
            access_information=AccessInformation(
                where_to_access_dataset="analytical_platform",
                s3_location="s3://databucket/",
            ),
        ),
    )
    client.upsert_database(database)

    response = client.search()
    assert response.facets.options("domains")
    assert client.search_facets().options("domains")


@runs_on_development_server
def test_filter_by_urn():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    database = Database(
        name="my_database",
        description="little test db",
        governance=Governance(
            data_owner=OwnerRef(
                urn="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
                display_name="April Gonzalez",
                email="abc@digital.justice.gov.uk",
            ),
            data_stewards=[
                OwnerRef(
                    urn="abc",
                    display_name="Jonjo Shelvey",
                    email="j.shelvey@digital.justice.gov.uk",
                )
            ],
        ),
        domain=DomainRef(urn="LAA", display_name="LAA"),
        last_modified=datetime(2020, 5, 17),
        creation_date=datetime(2020, 5, 17),
        access_information=AccessInformation(
            s3_location="s3://databucket/",
        ),
        tags=[TagRef(urn="test", display_name="test")],
        platform=EntityRef(urn="urn:li:dataPlatform:athena", display_name="athena"),
        custom_properties=CustomEntityProperties(
            usage_restrictions=UsageRestrictions(
                dpia_required=False,
                dpia_location=None,
            ),
            access_information=AccessInformation(
                where_to_access_dataset="analytical_platform",
                s3_location="s3://databucket/",
            ),
        ),
    )
    urn = client.upsert_database(database)

    response = client.search(
        filters=[MultiSelectFilter(filter_name="urn", included_values=[urn])]
    )
    assert response.total_results == 1


@runs_on_development_server
def test_fetch_dataset_belonging_to_data_product():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

    database = Database(
        name="my_database",
        description="little test db",
        display_name="database",
        governance=Governance(
            data_owner=OwnerRef(
                urn="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
                display_name="April Gonzalez",
                email="abc@digital.justice.gov.uk",
            ),
            data_stewards=[
                OwnerRef(
                    urn="abc",
                    display_name="Jonjo Shelvey",
                    email="j.shelvey@digital.justice.gov.uk",
                )
            ],
        ),
        domain=DomainRef(urn="LAA", display_name="LAA"),
        last_modified=datetime(2020, 5, 17),
        creation_date=datetime(2020, 5, 17),
        access_information=AccessInformation(
            s3_location="s3://databucket/",
        ),
        tags=[TagRef(urn="test", display_name="test")],
        platform=EntityRef(urn="urn:li:dataPlatform:athena", display_name="athena"),
        custom_properties=CustomEntityProperties(
            usage_restrictions=UsageRestrictions(
                dpia_required=False,
                dpia_location=None,
            ),
            access_information=AccessInformation(
                where_to_access_dataset="analytical_platform",
                s3_location="s3://databucket/",
            ),
        ),
    )
    client.upsert_database(database)

    table = Table(
        urn=None,
        display_name="Foo.Dataset",
        name="Dataset",
        fully_qualified_name="Foo.Dataset",
        description="Dataset",
        relationships={
            RelationshipType.PARENT: [
                EntityRef(urn="urn:li:container:my_database", display_name="database")
            ]
        },
        domain=DomainRef(display_name="", urn=""),
        governance=Governance(
            data_owner=OwnerRef(
                display_name="", email="Contact email for the user", urn=""
            ),
            data_stewards=[
                OwnerRef(display_name="", email="Contact email for the user", urn="")
            ],
        ),
        tags=[TagRef(display_name="some-tag", urn="urn:li:tag:Entity")],
        last_modified=datetime(2024, 3, 5, 6, 16, 47, 814000, tzinfo=timezone.utc),
        created=None,
        column_details=[
            Column(
                name="urn",
                display_name="urn",
                type="string",
                description="The primary identifier for the dataset entity.",
                nullable=False,
                is_primary_key=True,
                foreign_keys=[
                    ColumnRef(
                        name="urn",
                        display_name="urn",
                        table=EntityRef(
                            urn="urn:li:dataset:(urn:li:dataPlatform:datahub,Dataset,PROD)",
                            display_name="Dataset",
                        ),
                    )
                ],
            ),
        ],
        platform=EntityRef(urn="urn:li:dataPlatform:athena", display_name="athena"),
        custom_properties=CustomEntityProperties(
            access_information=AccessInformation(
                where_to_access_dataset="", source_dataset_name="", s3_location=None
            ),
            data_summary=DataSummary(row_count=5),
            usage_restrictions=UsageRestrictions(
                dpia_required=True,
                dpia_location=None,
            ),
        ),
    )
    urn = client.upsert_table(table=table)
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
def test_list_database_tables():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)
    assets = client.list_database_tables(
        urn="urn:li:dataProduct:my_data_product", count=20
    )
    assert assets


@runs_on_development_server
def test_get_glossary_terms_returns():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)
    assets = client.get_glossary_terms(count=20)
    assert assets


@runs_on_development_server
def test_get_chart():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)
    table = client.get_chart_details(urn="urn:li:chart:(justice-data,absconds)")
    assert table


@runs_on_development_server
def test_get_dataset():
    client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)
    table = client.get_table_details(
        urn="urn:li:dataset:(urn:li:dataPlatform:glue,nomis.agency_release_beds,PROD)"
    )
    assert table


# @runs_on_development_server
# def test_athena_upsert_test_hierarchy():
#     client = DataHubCatalogueClient(jwt_token=jwt_token, api_url=api_url)

#     database = Database(
#         name="my_database",
#         description="testing",
#         version="v1.0.0",
#         owner="2e1fa91a-c607-49e4-9be2-6f072ebe27c7",
#         owner_display_name="April Gonzalez",
#         maintainer="j.shelvey@digital.justice.gov.uk",
#         maintainer_display_name="Jonjo Shelvey",
#         email="justice@justice.gov.uk",
#         retention_period_in_days=365,
#         domain="prison",
#         subdomain=None,
#         dpia_required=False,
#         dpia_location=None,
#         last_modified=datetime(2020, 5, 17),
#         creation_date=datetime(2020, 5, 17),
#         s3_location="s3://databucket/",
#         tags=["test"],
#     )

#     table = Table(
#         name="test_table",
#         parent_database_name="my_database",
#         description="bla bla",
#         column_details=[
#             {"name": "foo", "type": "string", "description": "a"},
#             {"name": "bar", "type": "int", "description": "b"},
#         ],
#         retention_period_in_days=365,
#         where_to_access_dataset="analytical_platform",
#         tags=["test"],
#     )

#     # This function doesn't exist after the refactor. Unsure if we still need the test.
#     table_fqn = client.upsert_athena_table(
#         metadata=table,
#         database_metadata=database,
#     )
#     assert (
#         table_fqn
#         == "urn:li:dataset:(urn:li:dataPlatform:athena,my_database.test_table,PROD)"
#     )

#     # Ensure data went through
#     assert client.graph.get_aspect(table_fqn, DatasetPropertiesClass)
#     assert client.graph.get_aspect(table_fqn, SchemaMetadataClass)

#     dataset_properties = client.graph.get_aspect(
#         table_fqn, aspect_type=DatasetPropertiesClass
#     )
#     # check properties been loaded to datahub dataset
#     assert dataset_properties.description == table.description
#     assert dataset_properties.qualifiedName == f"{database.name}.{table.name}"
#     assert dataset_properties.name == table.name
#     assert (
#         dataset_properties.customProperties["sourceDatasetName"]
#         == table.source_dataset_name
#     )
#     assert (
#         dataset_properties.customProperties["whereToAccessDataset"]
#         == table.where_to_access_dataset
#     )
