import json
import logging
from datetime import datetime
from importlib.resources import files
from typing import Any, Sequence

from data_platform_catalogue.search_types import (
    ResultType,
    SearchResponse,
    SearchResult,
)
from datahub.configuration.common import GraphError
from datahub.ingestion.graph.client import DataHubGraph

logger = logging.getLogger(__name__)


class SearchClient:
    def __init__(self, graph: DataHubGraph):
        self.graph = graph
        self.search_query = (
            files("data_platform_catalogue.client.datahub.graphql")
            .joinpath("search.graphql")
            .read_text()
        )

    def search(
        self,
        query: str = "*",
        count: int = 20,
        page: str | None = None,
        result_types: Sequence[ResultType] = (
            ResultType.DATA_PRODUCT,
            ResultType.TABLE,
        ),
    ) -> SearchResponse:
        """
        Wraps the catalogue's search function.
        """
        if page is None:
            start = 0
        else:
            start = int(page)

        types = self._map_result_types(result_types)

        variables = {"count": count, "query": query, "start": start, "types": types}

        try:
            response = self.graph.execute_graphql(self.search_query, variables)
        except GraphError as e:
            raise Exception("Unable to execute search") from e

        page_results = []
        response = response["searchAcrossEntities"]

        logger.debug(json.dumps(response, indent=2))

        for result in response["searchResults"]:
            entity = result["entity"]
            entity_type = entity["type"]
            matched_fields = {
                i["name"]: i["value"] for i in result.get("matchedFields", [])
            }

            if entity_type == "DATA_PRODUCT":
                page_results.append(self._parse_data_product(entity, matched_fields))
            elif entity_type == "DATASET":
                page_results.append(self._parse_dataset(entity, matched_fields))
            else:
                raise ValueError(f"Unexpected entity type: {entity_type}")

        return SearchResponse(
            total_results=response["total"], page_results=page_results
        )

    def _map_result_types(self, result_types: Sequence[ResultType]):
        """
        Map result types to Datahub EntityTypes
        """
        types = []
        if ResultType.DATA_PRODUCT in result_types:
            types.append("DATA_PRODUCT")
        if ResultType.TABLE in result_types:
            types.append("DATASET")
        return types

    def _parse_owner(self, entity: dict[str, Any]):
        """
        Parse ownership information, if it is set.
        """
        ownership = entity.get("ownership") or {}
        owners = [i["owner"] for i in ownership.get("owners", [])]
        if owners:
            properties = owners[0].get("properties") or {}
            owner_email = properties.get("email", "")
            owner_name = properties.get("fullName", properties.get("displayName", ""))
        else:
            owner_email = ""
            owner_name = ""

        return owner_email, owner_name

    def _parse_last_updated(self, entity: dict[str, Any]) -> datetime | None:
        """
        Parse the last updated timestamp, if available
        """
        timestamp = entity.get("lastIngested")
        if timestamp is None:
            return None
        return datetime.utcfromtimestamp(timestamp / 1000)

    def _parse_tags(self, entity: dict[str, Any]) -> list[str]:
        """
        Parse tag information into a flat list of strings for displaying
        as part of the search result.
        """
        outer_tags = entity.get("tags") or {}
        tags = []
        for tag in outer_tags.get("tags", []):
            properties = tag["tag"]["properties"]
            if properties:
                tags.append(properties["name"])
        return tags

    def _parse_properties(self, entity: dict[str, Any]) -> dict[str, Any]:
        """
        Parse properties and editableProperties into a single dictionary.
        """
        properties = entity["properties"] or {}
        editable_properties = entity.get("editableProperties") or {}
        properties.update(editable_properties)
        return properties

    def _parse_dataset(self, entity: dict[str, Any], matches) -> SearchResult:
        """
        Map a dataset entity to a SearchResult
        """
        owner_email, owner_name = self._parse_owner(entity)
        properties = self._parse_properties(entity)
        tags = self._parse_tags(entity)
        last_updated = self._parse_last_updated(entity)
        name = entity["name"]

        return SearchResult(
            id=entity["urn"],
            result_type=ResultType.TABLE,
            matches=matches,
            name=properties.get("name", name),
            description=properties.get("description", ""),
            metadata={
                "owner": owner_name,
                "owner_email": owner_email,
            },
            tags=tags,
            last_updated=last_updated,
        )

    def _parse_data_product(self, entity: dict[str, Any], matches) -> SearchResult:
        """
        Map a data product entity to a SearchResult
        """
        domain = entity["domain"]["domain"]
        owner_email, owner_name = self._parse_owner(entity)
        properties = self._parse_properties(entity)
        tags = self._parse_tags(entity)
        last_updated = self._parse_last_updated(entity)

        return SearchResult(
            id=entity["urn"],
            result_type=ResultType.DATA_PRODUCT,
            matches=matches,
            name=properties["name"],
            description=properties.get("description", ""),
            metadata={
                "owner": owner_name,
                "owner_email": owner_email,
                "domain": domain,
            },
            tags=tags,
            last_updated=last_updated,
        )
