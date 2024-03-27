import json
import logging
from importlib.resources import files
from typing import Any, Sequence

from data_platform_catalogue.entities import RelationshipType
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
from .graphql_helpers import (
    parse_created_and_modified,
    parse_domain,
    parse_last_updated,
    parse_owner,
    parse_properties,
    parse_relations,
    parse_tags,
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
        self.get_glossary_terms_query = (
            files("data_platform_catalogue.client.datahub.graphql")
            .joinpath("getGlossaryTerms.graphql")
            .read_text()
        )

        self.get_database_tables_query = (
            files("data_platform_catalogue.client.datahub.graphql")
            .joinpath("listContainerEntities.graphql")
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
            ResultType.CHART,
            ResultType.DATABASE,
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
            matched_fields = self._get_matched_fields(result=result)

            if entity_type == "DATA_PRODUCT":
                page_results.append(self._parse_data_product(entity, matched_fields))
            elif entity_type == "DATASET":
                page_results.append(self._parse_dataset(entity, matched_fields))
            elif entity_type == "CHART":
                page_results.append(self._parse_chart(entity, matched_fields))
            elif entity_type == "CONTAINER":
                page_results.append(self._parse_container(entity, matched_fields))
            else:
                raise ValueError(f"Unexpected entity type: {entity_type}")

        return SearchResponse(
            total_results=response["total"], page_results=page_results, facets=facets
        )

    @staticmethod
    def _get_matched_fields(result: dict) -> dict:
        fields = result.get("matchedFields", [])
        matched_fields = {}
        for field in fields:
            name = field.get("name")
            value = field.get("value")
            if name == "customProperties" and value != "":
                name, value = value.split("=")
            matched_fields[name] = value
        return matched_fields

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
        page_results = self._get_data_collection_page_results(
            response, "listDataProductAssets"
        )

        return SearchResponse(
            total_results=response["listDataProductAssets"]["total"],
            page_results=page_results,
        )

    def list_database_tables(
        self, urn: str, count: int, start: int = 0
    ) -> SearchResponse:
        variables = {
            "urn": urn,
            "start": start,
            "count": count,
        }

        try:
            response = self.graph.execute_graphql(
                self.get_database_tables_query, variables
            )
        except GraphError as e:
            raise Exception("Unable to execute listDatabaseEntities query") from e

        page_results = self._get_data_collection_page_results(
            response["container"], "entities"
        )

        return SearchResponse(
            total_results=response["container"]["entities"]["total"],
            page_results=page_results,
        )

    def _get_data_collection_page_results(self, response, key_for_results: str):
        """
        for use by entities that hold collections of data, eg. data product and container
        """
        page_results = []
        for result in response[key_for_results]["searchResults"]:
            entity = result["entity"]
            entity_type = entity["type"]
            matched_fields: dict = {}
            if entity_type == "DATASET":
                page_results.append(self._parse_dataset(entity, matched_fields))
            else:
                raise ValueError(f"Unexpected entity type: {entity_type}")
        return page_results

    def _map_result_types(self, result_types: Sequence[ResultType]):
        """
        Map result types to Datahub EntityTypes
        """
        types = []
        if ResultType.DATA_PRODUCT in result_types:
            types.append("DATA_PRODUCT")
        if ResultType.TABLE in result_types:
            types.append("DATASET")
        if ResultType.GLOSSARY_TERM in result_types:
            types.append("GLOSSARY_TERM")
        if ResultType.CHART in result_types:
            types.append("CHART")
        if ResultType.DATABASE in result_types:
            types.append("CONTAINER")

        return types

    def _map_filters(self, filters: Sequence[MultiSelectFilter]):
        result = []
        for filter in filters:
            result.append(
                {"field": filter.filter_name, "values": filter.included_values}
            )
        return result

    def _parse_dataset(self, entity: dict[str, Any], matches) -> SearchResult:
        """
        Map a dataset entity to a SearchResult
        """
        owner_email, owner_name = parse_owner(entity)
        properties, custom_properties = parse_properties(entity)
        tags = parse_tags(entity)
        last_updated = parse_last_updated(entity)
        name = entity["name"]

        relations = parse_relations(
            RelationshipType.PARENT, entity.get("relationships", {})
        )

        metadata = {
            "owner": owner_name,
            "owner_email": owner_email,
            "total_parents": entity.get("relationships", {}).get("total", 0),
            "parents": relations[RelationshipType.PARENT],
            "entity_types": self._parse_types_and_sub_types(entity, "Dataset"),
        }
        metadata.update(parse_domain(entity))
        metadata.update(custom_properties)

        fqn = self._get_fully_qualified_name(properties, name)

        created, modified = parse_created_and_modified(properties)

        return SearchResult(
            id=entity["urn"],
            result_type=ResultType.TABLE,
            matches=matches,
            name=properties.get("name", name),
            fully_qualified_name=fqn,
            description=properties.get("description", ""),
            metadata=metadata,
            tags=tags,
            last_updated=modified or last_updated,
            first_created=created,
        )

    def _parse_data_product(self, entity: dict[str, Any], matches) -> SearchResult:
        """
        Map a data product entity to a SearchResult
        """
        owner_email, owner_name = parse_owner(entity)
        properties, custom_properties = parse_properties(entity)
        tags = parse_tags(entity)
        last_updated = parse_last_updated(entity)
        metadata = {
            "owner": owner_name,
            "owner_email": owner_email,
            "number_of_assets": properties["numAssets"],
        }
        metadata.update(parse_domain(entity))
        metadata.update(custom_properties)

        fqn = self._get_fully_qualified_name(properties, properties["name"])

        return SearchResult(
            id=entity["urn"],
            result_type=ResultType.DATA_PRODUCT,
            matches=matches,
            name=properties["name"],
            fully_qualified_name=fqn,
            description=properties.get("description", ""),
            metadata=metadata,
            tags=tags,
            last_updated=last_updated,
        )

    def _parse_chart(self, entity: dict[str, Any], matches) -> SearchResult:
        properties, custom_properties = parse_properties(entity)
        last_updated = parse_last_updated(entity)

        return SearchResult(
            id=entity["urn"],
            result_type=ResultType.CHART,
            matches=matches,
            name=properties["name"],
            fully_qualified_name=properties["name"],
            description=properties.get("description", ""),
            metadata=custom_properties,
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

    def _parse_glossary_term(self, entity) -> SearchResult:
        properties, custom_properties = parse_properties(entity)
        metadata = {"parentNodes": entity["parentNodes"]["nodes"]}

        return SearchResult(
            id=entity["urn"],
            result_type=ResultType.GLOSSARY_TERM,
            matches={},
            name=properties["name"],
            description=properties.get("description", ""),
            metadata=metadata,
            tags=[],
            last_updated=None,
        )

    def get_glossary_terms(self, count: int = 1000) -> SearchResponse:
        "Get some number of glossary terms from DataHub"
        variables = {"count": count}
        try:
            response = self.graph.execute_graphql(
                self.get_glossary_terms_query, variables
            )
        except GraphError as e:
            raise Exception("Unable to execute getGlossaryTerms query") from e

        page_results = []
        response = response["searchAcrossEntities"]
        logger.debug(json.dumps(response, indent=2))

        for result in response["searchResults"]:
            page_results.append(self._parse_glossary_term(entity=result["entity"]))

        return SearchResponse(
            total_results=response["total"], page_results=page_results
        )

    def _parse_container(self, entity: dict[str, Any], matches) -> SearchResult:
        """
        Map a Container entity to a SearchResult
        """
        tags = parse_tags(entity)
        last_updated = parse_last_updated(entity)
        properties, custom_properties = parse_properties(entity)
        owner_email, owner_name = parse_owner(entity)

        metadata = {
            "owner": owner_name,
            "owner_email": owner_email,
            "entity_types": self._parse_types_and_sub_types(entity, "Container"),
        }

        fqn = self._get_fully_qualified_name(properties, properties["name"])

        metadata.update(parse_domain(entity))
        metadata.update(custom_properties)

        return SearchResult(
            id=entity["urn"],
            result_type=ResultType.DATABASE,
            matches=matches,
            name=properties["name"],
            fully_qualified_name=fqn,
            description=properties.get("description", ""),
            metadata=metadata,
            tags=tags,
            last_updated=last_updated,
        )

    def _parse_types_and_sub_types(self, entity: dict, entity_type: str) -> dict:
        entity_sub_type = (
            entity.get("subTypes", {}).get("typeNames", [entity_type])
            if entity.get("subTypes") is not None
            else [entity_type]
        )
        return {"entity_type": entity_type, "entity_sub_types": entity_sub_type}

    def _get_fully_qualified_name(self, entity_properties: dict, name: str) -> str:
        fqn = (
            entity_properties.get("qualifiedName", name)
            if entity_properties.get("qualifiedName") is not None
            else name
        )
        return fqn
