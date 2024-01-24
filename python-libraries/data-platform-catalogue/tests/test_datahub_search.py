from datetime import datetime
from unittest.mock import MagicMock

import pytest
from data_platform_catalogue.client.datahub.search import SearchClient
from data_platform_catalogue.search_types import (
    ResultType,
    SearchResponse,
    SearchResult,
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
                description="Prisons in England and Wales are required to record all instances of Use of Force within their establishment. Use of Force can be planned or unplanned and may involve various categories of control and restraint (C&R) techniques such as physical restraint or handcuffs.\n\nPlease refer to [PSO 1600](https://www.gov.uk/government/publications/use-of-force-in-prisons-pso-1600) for the current guidance.",  # noqa E501
                metadata={
                    "domain": {
                        "id": "3dc18e48-c062-4407-84a9-73e23f768023",
                        "properties": {
                            "name": "HMPPS",
                            "description": "HMPPS is an executive agency that carries out sentences given by the courts, in custody and the community, and rehabilitates people through education and employment.",  # noqa E501
                        },
                        "urn": "urn:li:domain:3dc18e48-c062-4407-84a9-73e23f768023",
                    },
                    "owner": "",
                    "owner_email": "",
                },
                tags=["custody"],
            )
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
                        "properties": {
                            "name": "customers2",
                        },
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
                description="",
                metadata={"owner": "", "owner_email": ""},
                tags=[],
                last_updated=datetime(2024, 1, 23, 6, 15, 2, 353000),
            ),
            SearchResult(
                id="urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers2,PROD)",
                matches={},
                result_type=ResultType.TABLE,
                name="customers2",
                description="",
                metadata={"owner": "", "owner_email": ""},
                tags=[],
                last_updated=None,
            ),
            SearchResult(
                id="urn:li:dataset:(urn:li:dataPlatform:bigquery,calm-pagoda-323403.jaffle_shop.customers3,PROD)",
                matches={},
                result_type=ResultType.TABLE,
                name="customers3",
                description="",
                metadata={"owner": "", "owner_email": ""},
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
                description="",
                metadata={"owner": "", "owner_email": ""},
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
                description="",
                metadata={
                    "owner": "Shannon Lovett",
                    "owner_email": "shannon@longtail.com",
                },
                tags=[],
            )
        ],
    )
