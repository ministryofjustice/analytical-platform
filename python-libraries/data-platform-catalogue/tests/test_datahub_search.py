from datetime import datetime
from unittest.mock import MagicMock

import pytest
from data_platform_catalogue.client.datahub.search import SearchClient
from data_platform_catalogue.search_types import (
    FacetOption,
    MultiSelectFilter,
    ResultType,
    SearchFacets,
    SearchResponse,
    SearchResult,
    SortOption,
)


@pytest.fixture
def mock_graph():
    return MagicMock()


@pytest.fixture
def searcher(mock_graph):
    return SearchClient(mock_graph)


def test_empty_search_results(mock_graph, searcher):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 0,
            "total": 0,
            "searchResults": [],
        }
    }
    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search()
    assert response == SearchResponse(total_results=0, page_results=[])


def test_one_search_result(mock_graph, searcher):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 1,
            "total": 1,
            "searchResults": [
                {
                    "entity": {
                        "type": "DATA_PRODUCT",
                        "urn": "urn:li:dataProduct:6cc5cbc4-c002-42c3-b80b-ed55df17d39f",
                        "ownership": None,
                        "properties": {
                            "name": "Use of force",
                            "description": "Prisons in England and Wales are required to record all instances of Use of Force within their establishment. Use of Force can be planned or unplanned and may involve various categories of control and restraint (C&R) techniques such as physical restraint or handcuffs.\n\nPlease refer to [PSO 1600](https://www.gov.uk/government/publications/use-of-force-in-prisons-pso-1600) for the current guidance.",  # noqa E501
                            "customProperties": [],
                            "numAssets": 7,
                        },
                        "domain": {
                            "domain": {
                                "urn": "urn:li:domain:3dc18e48-c062-4407-84a9-73e23f768023",
                                "id": "3dc18e48-c062-4407-84a9-73e23f768023",
                                "properties": {
                                    "name": "HMPPS",
                                    "description": "HMPPS is an executive agency that carries out sentences given by the courts, in custody and the community, and rehabilitates people through education and employment.",  # noqa E501
                                },
                            }
                        },
                        "tags": {
                            "tags": [
                                {
                                    "tag": {
                                        "urn": "urn:li:tag:custody",
                                        "properties": {
                                            "name": "custody",
                                            "description": "Data about prisons and prisoners. Not just NOMIS!",
                                        },
                                    }
                                }
                            ]
                        },
                    }
                }
            ],
        }
    }
    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search()
    assert response == SearchResponse(
        total_results=1,
        page_results=[
            SearchResult(
                id="urn:li:dataProduct:6cc5cbc4-c002-42c3-b80b-ed55df17d39f",
                matches={},
                result_type=ResultType.DATA_PRODUCT,
                name="Use of force",
                fully_qualified_name="Use of force",
                description="Prisons in England and Wales are required to record all instances of Use of Force within their establishment. Use of Force can be planned or unplanned and may involve various categories of control and restraint (C&R) techniques such as physical restraint or handcuffs.\n\nPlease refer to [PSO 1600](https://www.gov.uk/government/publications/use-of-force-in-prisons-pso-1600) for the current guidance.",  # noqa E501
                metadata={
                    "domain_id": "urn:li:domain:3dc18e48-c062-4407-84a9-73e23f768023",
                    "domain_name": "HMPPS",
                    "owner": "",
                    "owner_email": "",
                    "number_of_assets": 7,
                },
                tags=["custody"],
            )
        ],
    )


def test_dataset_result(mock_graph, searcher):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 1,
            "total": 1,
            "searchResults": [
                {
                    "insights": [],
                    "matchedFields": [],
                    "entity": {
                        "type": "DATASET",
                        "urn": "urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",  # noqa E501
                        "platform": {"name": "bigquery"},
                        "ownership": None,
                        "name": "calm-pagoda-323403.jaffle_shop.customers",
                        "properties": {
                            "name": "customers",
                            "qualifiedName": "jaffle_shop.customers",
                            "customProperties": [
                                {"key": "StoredAsSubDirectories", "value": "False"},
                                {
                                    "key": "CreatedByJob",
                                    "value": "moj-reg-prod-hmpps-assess-risks-and-needs-prod-glue-job",
                                },
                            ],
                        },
                        "domain": {
                            "domain": {
                                "urn": "urn:li:domain:3dc18e48-c062-4407-84a9-73e23f768023",
                                "id": "3dc18e48-c062-4407-84a9-73e23f768023",
                                "properties": {
                                    "name": "HMPPS",
                                    "description": "HMPPS is an executive agency that ...",
                                },
                            },
                            "editableProperties": None,
                            "tags": None,
                            "lastIngested": 1705990502353,
                        },
                    },
                }
            ],
        }
    }
    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search()
    assert response == SearchResponse(
        total_results=1,
        page_results=[
            SearchResult(
                id="urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",
                matches={},
                result_type=ResultType.TABLE,
                name="customers",
                fully_qualified_name="jaffle_shop.customers",
                description="",
                metadata={
                    "owner": "",
                    "owner_email": "",
                    "data_products": [],
                    "total_data_products": 0,
                    "domain_name": "HMPPS",
                    "domain_id": "urn:li:domain:3dc18e48-c062-4407-84a9-73e23f768023",
                    "StoredAsSubDirectories": "False",
                    "CreatedByJob": "moj-reg-prod-hmpps-assess-risks-and-needs-prod-glue-job",
                },
                tags=[],
            ),
        ],
    )


def test_full_page(mock_graph, searcher):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 3,
            "total": 5,
            "searchResults": [
                {
                    "insights": [],
                    "matchedFields": [],
                    "entity": {
                        "type": "DATASET",
                        "urn": "urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",  # noqa E501
                        "platform": {"name": "bigquery"},
                        "ownership": None,
                        "name": "calm-pagoda-323403.jaffle_shop.customers",
                        "properties": {
                            "name": "customers",
                            "qualifiedName": "jaffle_shop.customers",
                        },
                        "editableProperties": None,
                        "tags": None,
                        "lastIngested": 1705990502353,
                    },
                },
                {
                    "insights": [],
                    "matchedFields": [],
                    "entity": {
                        "type": "DATASET",
                        "urn": "urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers2,PROD)",  # noqa E501
                        "name": "calm-pagoda-323403.jaffle_shop.customers2",
                        "properties": {"name": "customers2", "qualifiedName": None},
                    },
                },
                {
                    "insights": [],
                    "matchedFields": [],
                    "entity": {
                        "type": "DATASET",
                        "urn": "urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers3,PROD)",  # noqa E501
                        "name": "calm-pagoda-323403.jaffle_shop.customers3",
                        "properties": {
                            "name": "customers3",
                        },
                    },
                },
            ],
        }
    }
    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search()
    assert response == SearchResponse(
        total_results=5,
        page_results=[
            SearchResult(
                id="urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",
                matches={},
                result_type=ResultType.TABLE,
                name="customers",
                fully_qualified_name="jaffle_shop.customers",
                description="",
                metadata={
                    "owner": "",
                    "owner_email": "",
                    "data_products": [],
                    "total_data_products": 0,
                    "domain_name": "",
                    "domain_id": "",
                },
                tags=[],
                last_updated=datetime(2024, 1, 23, 6, 15, 2, 353000),
            ),
            SearchResult(
                id="urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers2,PROD)",
                matches={},
                result_type=ResultType.TABLE,
                name="customers2",
                fully_qualified_name="calm-pagoda-323403.jaffle_shop.customers2",
                description="",
                metadata={
                    "owner": "",
                    "owner_email": "",
                    "data_products": [],
                    "total_data_products": 0,
                    "domain_name": "",
                    "domain_id": "",
                },
                tags=[],
                last_updated=None,
            ),
            SearchResult(
                id="urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers3,PROD)",
                matches={},
                result_type=ResultType.TABLE,
                name="customers3",
                fully_qualified_name="calm-pagoda-323403.jaffle_shop.customers3",
                description="",
                metadata={
                    "owner": "",
                    "owner_email": "",
                    "data_products": [],
                    "total_data_products": 0,
                    "domain_name": "",
                    "domain_id": "",
                },
                tags=[],
                last_updated=None,
            ),
        ],
    )


def test_query_match(mock_graph, searcher):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 1,
            "total": 1,
            "searchResults": [
                {
                    "insights": [],
                    "matchedFields": [
                        {
                            "name": "urn",
                            "value": "urn:li:dataset:(urn:li:dataPlatform:looker,long_tail_companions.view.customer_focused,PROD)",  # noqa E501
                        },
                        {"name": "name", "value": "customer_focused"},
                    ],
                    "entity": {
                        "type": "DATASET",
                        "urn": "urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",  # noqa E501
                        "name": "calm-pagoda-323403.jaffle_shop.customers",
                        "properties": {
                            "name": "customers",
                        },
                    },
                }
            ],
        }
    }

    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search()
    assert response == SearchResponse(
        total_results=1,
        page_results=[
            SearchResult(
                id="urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",
                matches={
                    "urn": "urn:li:dataset:(urn:li:dataPlatform:looker,long_tail_companions.view.customer_focused,PROD)",  # noqa E501
                    "name": "customer_focused",
                },
                result_type=ResultType.TABLE,
                name="customers",
                fully_qualified_name="calm-pagoda-323403.jaffle_shop.customers",
                description="",
                metadata={
                    "owner": "",
                    "owner_email": "",
                    "data_products": [],
                    "total_data_products": 0,
                    "domain_id": "",
                    "domain_name": "",
                },
                tags=[],
            )
        ],
    )


def test_result_with_owner(mock_graph, searcher):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 1,
            "total": 1,
            "searchResults": [
                {
                    "entity": {
                        "type": "DATASET",
                        "urn": "urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",  # noqa E501
                        "name": "calm-pagoda-323403.jaffle_shop.customers",
                        "ownership": {
                            "owners": [
                                {
                                    "owner": {
                                        "urn": "urn:li:corpuser:shannon@longtail.com",
                                        "properties": {
                                            "fullName": "Shannon Lovett",
                                            "email": "shannon@longtail.com",
                                        },
                                    }
                                }
                            ]
                        },
                        "properties": {
                            "name": "customers",
                        },
                    },
                }
            ],
        }
    }

    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search()
    assert response == SearchResponse(
        total_results=1,
        page_results=[
            SearchResult(
                id="urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",
                matches={},
                result_type=ResultType.TABLE,
                name="customers",
                fully_qualified_name="calm-pagoda-323403.jaffle_shop.customers",
                description="",
                metadata={
                    "owner": "Shannon Lovett",
                    "owner_email": "shannon@longtail.com",
                    "data_products": [],
                    "total_data_products": 0,
                    "domain_id": "",
                    "domain_name": "",
                },
                tags=[],
            )
        ],
    )


def test_filter(searcher, mock_graph):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 0,
            "total": 0,
            "searchResults": [],
        }
    }
    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search(filters=[MultiSelectFilter("domains", ["Abc", "Def"])])

    assert response == SearchResponse(
        total_results=0,
        page_results=[],
    )


def test_sort(searcher, mock_graph):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 0,
            "total": 0,
            "searchResults": [],
        }
    }
    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search(sort=SortOption(field="name", ascending=False))

    assert response == SearchResponse(
        total_results=0,
        page_results=[],
    )


def test_facets(searcher, mock_graph):
    datahub_response = {
        "aggregateAcrossEntities": {
            "facets": [
                {
                    "field": "_entityType",
                    "displayName": "Type",
                    "aggregations": [
                        {"value": "DATASET", "count": 1505, "entity": None}
                    ],
                },
                {
                    "field": "glossaryTerms",
                    "displayName": "Glossary Term",
                    "aggregations": [
                        {
                            "value": "urn:li:glossaryTerm:Classification.Sensitive",
                            "count": 1,
                            "entity": {"properties": {"name": "Sensitive"}},
                        },
                        {
                            "value": "urn:li:glossaryTerm:Silver",
                            "count": 1,
                            "entity": {"properties": None},
                        },
                    ],
                },
                {
                    "field": "domains",
                    "displayName": "Domain",
                    "aggregations": [
                        {
                            "value": "urn:li:domain:094dc54b-0ebc-40a6-a4cf-e1b75e8b8089",
                            "count": 7,
                            "entity": {"properties": {"name": "Pet Adoptions"}},
                        },
                        {
                            "value": "urn:li:domain:7186eeff-a860-4b0a-989f-69473a0c9c67",
                            "count": 4,
                            "entity": {"properties": {"name": "E-Commerce"}},
                        },
                    ],
                },
            ],
        }
    }

    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search_facets()

    assert response == SearchFacets(
        {
            "glossaryTerms": [
                FacetOption(
                    value="urn:li:glossaryTerm:Classification.Sensitive",
                    label="Sensitive",
                    count=1,
                ),
                FacetOption(
                    value="urn:li:glossaryTerm:Silver",
                    label="urn:li:glossaryTerm:Silver",
                    count=1,
                ),
            ],
            "domains": [
                FacetOption(
                    value="urn:li:domain:094dc54b-0ebc-40a6-a4cf-e1b75e8b8089",
                    label="Pet Adoptions",
                    count=7,
                ),
                FacetOption(
                    value="urn:li:domain:7186eeff-a860-4b0a-989f-69473a0c9c67",
                    label="E-Commerce",
                    count=4,
                ),
            ],
        }
    )


def test_search_results_with_facets(searcher, mock_graph):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 10,
            "total": 10,
            "searchResults": [],
            "facets": [
                {
                    "field": "_entityType",
                    "displayName": "Type",
                    "aggregations": [
                        {"value": "DATASET", "count": 1505, "entity": None}
                    ],
                },
                {
                    "field": "glossaryTerms",
                    "displayName": "Glossary Term",
                    "aggregations": [
                        {
                            "value": "urn:li:glossaryTerm:Classification.Sensitive",
                            "count": 1,
                            "entity": {"properties": {"name": "Sensitive"}},
                        },
                        {
                            "value": "urn:li:glossaryTerm:Silver",
                            "count": 1,
                            "entity": {"properties": None},
                        },
                    ],
                },
                {
                    "field": "domains",
                    "displayName": "Domain",
                    "aggregations": [
                        {
                            "value": "urn:li:domain:094dc54b-0ebc-40a6-a4cf-e1b75e8b8089",
                            "count": 7,
                            "entity": {"properties": {"name": "Pet Adoptions"}},
                        },
                        {
                            "value": "urn:li:domain:7186eeff-a860-4b0a-989f-69473a0c9c67",
                            "count": 4,
                            "entity": {"properties": {"name": "E-Commerce"}},
                        },
                    ],
                },
            ],
        }
    }

    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search()

    assert response == SearchResponse(
        total_results=10,
        page_results=[],
        facets=SearchFacets(
            {
                "glossaryTerms": [
                    FacetOption(
                        value="urn:li:glossaryTerm:Classification.Sensitive",
                        label="Sensitive",
                        count=1,
                    ),
                    FacetOption(
                        value="urn:li:glossaryTerm:Silver",
                        label="urn:li:glossaryTerm:Silver",
                        count=1,
                    ),
                ],
                "domains": [
                    FacetOption(
                        value="urn:li:domain:094dc54b-0ebc-40a6-a4cf-e1b75e8b8089",
                        label="Pet Adoptions",
                        count=7,
                    ),
                    FacetOption(
                        value="urn:li:domain:7186eeff-a860-4b0a-989f-69473a0c9c67",
                        label="E-Commerce",
                        count=4,
                    ),
                ],
            }
        ),
    )


def test_result_with_data_product(mock_graph, searcher):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 1,
            "total": 1,
            "searchResults": [
                {
                    "entity": {
                        "type": "DATASET",
                        "urn": "urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",  # noqa E501
                        "name": "calm-pagoda-323403.jaffle_shop.customers",
                        "relationships": {
                            "total": 1,
                            "relationships": [
                                {
                                    "entity": {
                                        "urn": "urn:abc",
                                        "properties": {"name": "abc"},
                                    }
                                }
                            ],
                        },
                        "properties": {
                            "name": "customers",
                        },
                    },
                }
            ],
        }
    }

    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.search()
    assert response == SearchResponse(
        total_results=1,
        page_results=[
            SearchResult(
                id="urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",
                matches={},
                result_type=ResultType.TABLE,
                name="customers",
                fully_qualified_name="calm-pagoda-323403.jaffle_shop.customers",
                description="",
                metadata={
                    "owner": "",
                    "owner_email": "",
                    "data_products": [{"id": "urn:abc", "name": "abc"}],
                    "total_data_products": 1,
                    "domain_id": "",
                    "domain_name": "",
                },
                tags=[],
            )
        ],
    )


def test_list_data_product_assets(mock_graph, searcher):
    datahub_response = {
        "listDataProductAssets": {
            "start": 0,
            "count": 20,
            "total": 1,
            "searchResults": [
                {
                    "entity": {
                        "type": "DATASET",
                        "urn": "urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",  # noqa E501
                        "name": "calm-pagoda-323403.jaffle_shop.customers",
                        "relationships": {
                            "total": 1,
                            "relationships": [
                                {
                                    "entity": {
                                        "urn": "urn:abc",
                                        "properties": {"name": "abc"},
                                    }
                                }
                            ],
                        },
                        "properties": {
                            "name": "customers",
                            "description": "just some customers",
                        },
                    },
                }
            ],
        }
    }

    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.list_data_product_assets(
        urn="urn:li:dataProduct:test",
        start=0,
        count=20,
    )

    assert response == SearchResponse(
        total_results=1,
        page_results=[
            SearchResult(
                id="urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers,PROD)",
                matches={},
                result_type=ResultType.TABLE,
                name="customers",
                fully_qualified_name="calm-pagoda-323403.jaffle_shop.customers",
                description="just some customers",
                metadata={
                    "owner": "",
                    "owner_email": "",
                    "data_products": [{"id": "urn:abc", "name": "abc"}],
                    "total_data_products": 1,
                    "domain_id": "",
                    "domain_name": "",
                },
                tags=[],
            )
        ],
    )


def test_get_glossary_terms(mock_graph, searcher):
    datahub_response = {
        "searchAcrossEntities": {
            "start": 0,
            "count": 2,
            "total": 2,
            "searchResults": [
                {
                    "entity": {
                        "urn": "urn:li:glossaryTerm:022b9b68-c211-47ae-aef0-2db13acfeca8",
                        "properties": {
                            "name": "IAO",
                            "description": "Information asset owner.\n",
                        },
                        "parentNodes": {
                            "nodes": [
                                {
                                    "properties": {
                                        "name": "Data protection terms",
                                        "description": "Data protection terms",
                                    }
                                }
                            ]
                        },
                    }
                },
                {
                    "entity": {
                        "urn": "urn:li:glossaryTerm:0eb7af28-62b4-4149-a6fa-72a8f1fea1e6",
                        "properties": {
                            "name": "Security classification",
                            "description": "Only data that is 'official'",
                        },
                        "parentNodes": {"nodes": []},
                    }
                },
            ],
        }
    }

    mock_graph.execute_graphql = MagicMock(return_value=datahub_response)

    response = searcher.get_glossary_terms(count=2)
    print(response)
    assert response == SearchResponse(
        total_results=2,
        page_results=[
            SearchResult(
                id="urn:li:glossaryTerm:022b9b68-c211-47ae-aef0-2db13acfeca8",
                name="IAO",
                description="Information asset owner.\n",
                metadata={
                    "parentNodes": [
                        {
                            "properties": {
                                "name": "Data protection terms",
                                "description": "Data protection terms",
                            }
                        }
                    ]
                },
                result_type=ResultType.GLOSSARY_TERM,
            ),
            SearchResult(
                id="urn:li:glossaryTerm:0eb7af28-62b4-4149-a6fa-72a8f1fea1e6",
                name="Security classification",
                description="Only data that is 'official'",
                metadata={"parentNodes": []},
                result_type=ResultType.GLOSSARY_TERM,
            ),
        ],
    )
