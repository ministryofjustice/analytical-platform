import json
import logging
from datetime import datetime
from importlib.resources import files
from typing import Any, Sequence, Tuple

from datahub.configuration.common import GraphError
from datahub.ingestion.graph.client import DataHubGraph

from ...search_types import (
    FacetOption,
    MultiSelectFilter,
    ResultType,
    SearchFacets,
    SearchResponse,
    SearchResult,
    SortOption,
)

logger = logging.getLogger(__name__)


class SearchClient:
    def __init__(self, graph: DataHubGraph):
        self.graph = graph
        self.search_query = (
            files("data_platform_catalogue.client.datahub.graphql")
            .joinpath("search.graphql")
            .read_text()
        )
        self.facets_query = (
            files("data_platform_catalogue.client.datahub.graphql")
            .joinpath("facets.graphql")
            .read_text()
        )

        self.data_product_asset_query = (
            files("data_platform_catalogue.client.datahub.graphql")
            .joinpath("listDataProductAssets.graphql")
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
        filters: Sequence[MultiSelectFilter] = (),
        sort: SortOption | None = None,
    ) -> SearchResponse:
        """
        Wraps the catalogue's search function.
        """
        if page is None:
            start = 0
        else:
            start = int(page) * count

        types = self._map_result_types(result_types)
        formatted_filters = self._map_filters(filters)

        variables = {
            "count": count,
            "query": query,
            "start": start,
            "types": types,
            "filters": formatted_filters,
        }

        if sort:
            variables.update({"sort": sort.format()})

        try:
            response = self.graph.execute_graphql(self.search_query, variables)
        except GraphError as e:
            raise Exception("Unable to execute search query") from e

        page_results = []
        response = response["searchAcrossEntities"]
        facets = self._parse_facets(response.get("facets", []))

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
            total_results=response["total"], page_results=page_results, facets=facets
        )

    def search_facets(
        self,
        query: str = "*",
        result_types: Sequence[ResultType] = (
            ResultType.DATA_PRODUCT,
            ResultType.TABLE,
        ),
        filters: Sequence[MultiSelectFilter] = (),
    ) -> SearchFacets:
        """
        Returns facets that can be used to filter the search results.
        """
        types = self._map_result_types(result_types)
        formatted_filters = self._map_filters(filters)

        variables = {
            "query": query,
            "facets": [],
            "types": types,
            "filters": formatted_filters,
        }

        try:
            response = self.graph.execute_graphql(self.facets_query, variables)
        except GraphError as e:
            raise Exception("Unable to execute facets query") from e

        response = response["aggregateAcrossEntities"]
        return self._parse_facets(response.get("facets", []))

    def list_data_product_assets(
        self, urn: str, count: int, start: int = 0
    ) -> SearchResponse:
        """
        returns a SearchResponse containing all assets in given data product (by urn)
        """
        variables = {
            "urn": urn,
            "query": "*",
            "start": start,
            "count": count,
        }
        try:
            response = self.graph.execute_graphql(
                self.data_product_asset_query, variables
            )
        except GraphError as e:
            raise Exception("Unable to execute listDataProductAssets query") from e
        page_results = []
        for result in response["listDataProductAssets"]["searchResults"]:
            entity = result["entity"]
            entity_type = entity["type"]
            matched_fields: dict = {}
            if entity_type == "DATASET":
                page_results.append(self._parse_dataset(entity, matched_fields))
            else:
                raise ValueError(f"Unexpected entity type: {entity_type}")

        return SearchResponse(
            total_results=response["listDataProductAssets"]["total"],
            page_results=page_results,
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

    def _map_filters(self, filters: Sequence[MultiSelectFilter]):
        result = []
        for filter in filters:
            result.append(
                {"field": filter.filter_name, "values": filter.included_values}
            )
        return result

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

    def _parse_properties(
        self, entity: dict[str, Any]
    ) -> Tuple[dict[str, Any], dict[str, Any]]:
        """
        Parse properties and editableProperties into a single dictionary.
        """
        properties = entity["properties"] or {}
        editable_properties = entity.get("editableProperties") or {}
        properties.update(editable_properties)
        custom_properties = {
            i["key"]: i["value"] for i in properties.get("customProperties", [])
        }
        return properties, custom_properties

    def _parse_domain(self, entity: dict[str, Any]):
        metadata = {}
        domain = entity.get("domain") or {}
        inner_domain = domain.get("domain") or {}
        metadata["domain_id"] = inner_domain.get("urn", "")
        if inner_domain:
            domain_properties, _ = self._parse_properties(inner_domain)
            metadata["domain_name"] = domain_properties.get("name", "")
        else:
            metadata["domain_name"] = ""
        return metadata

    def _parse_dataset(self, entity: dict[str, Any], matches) -> SearchResult:
        """
        Map a dataset entity to a SearchResult
        """
        owner_email, owner_name = self._parse_owner(entity)
        properties, custom_properties = self._parse_properties(entity)
        tags = self._parse_tags(entity)
        last_updated = self._parse_last_updated(entity)
        name = entity["name"]
        relationships = entity.get("relationships", {})
        total_data_products = relationships.get("total", 0)
        data_products = relationships.get("relationships", [])
        data_products = [
            {"id": i["entity"]["urn"], "name": i["entity"]["properties"]["name"]}
            for i in data_products
        ]

        metadata = {
            "owner": owner_name,
            "owner_email": owner_email,
            "total_data_products": total_data_products,
            "data_products": data_products,
        }
        metadata.update(self._parse_domain(entity))
        metadata.update(custom_properties)

        return SearchResult(
            id=entity["urn"],
            result_type=ResultType.TABLE,
            matches=matches,
            name=properties.get("name", name),
            description=properties.get("description", ""),
            metadata=metadata,
            tags=tags,
            last_updated=last_updated,
        )

    def _parse_data_product(self, entity: dict[str, Any], matches) -> SearchResult:
        """
        Map a data product entity to a SearchResult
        """
        owner_email, owner_name = self._parse_owner(entity)
        properties, custom_properties = self._parse_properties(entity)
        tags = self._parse_tags(entity)
        last_updated = self._parse_last_updated(entity)
        metadata = {
            "owner": owner_name,
            "owner_email": owner_email,
            "number_of_assets": properties["numAssets"],
        }
        metadata.update(self._parse_domain(entity))
        metadata.update(custom_properties)

        return SearchResult(
            id=entity["urn"],
            result_type=ResultType.DATA_PRODUCT,
            matches=matches,
            name=properties["name"],
            description=properties.get("description", ""),
            metadata=metadata,
            tags=tags,
            last_updated=last_updated,
        )

    def _parse_facets(self, facets: list[dict[str, Any]]) -> SearchFacets:
        """
        Parse the facets and aggregate information from the query results
        """
        results = {}
        for facet in facets:
            field = facet["field"]
            if field not in ("domains", "tags", "customProperties", "glossaryTerms"):
                continue

            options = []
            for aggregate in facet["aggregations"]:
                value = aggregate["value"]
                count = aggregate["count"]
                entity = aggregate.get("entity") or {}
                properties = entity.get("properties") or {}
                label = properties.get("name", value)
                options.append(FacetOption(value=value, label=label, count=count))

            results[field] = options

        return SearchFacets(results)
