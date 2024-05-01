import json
import logging
from importlib.resources import files
from typing import Any, Sequence

from data_platform_catalogue.client.exceptions import CatalogueError
from data_platform_catalogue.client.graphql_helpers import (
    parse_created_and_modified,
    parse_domain,
    parse_last_modified,
    parse_names,
    parse_owner,
    parse_properties,
    parse_relations,
    parse_tags,
)
from data_platform_catalogue.entities import RelationshipType
from data_platform_catalogue.search_types import (
    FacetOption,
    MultiSelectFilter,
    ResultType,
    SearchFacets,
    SearchResponse,
    SearchResult,
    SortOption,
)
from datahub.configuration.common import GraphError  # pylint: disable=E0611
from datahub.ingestion.graph.client import DataHubGraph  # pylint: disable=E0611

logger = logging.getLogger(__name__)


class SearchClient:
    def __init__(self, graph: DataHubGraph):
        self.graph = graph
        self.search_query = (
            files("data_platform_catalogue.client.graphql")
            .joinpath("search.graphql")
            .read_text()
        )
        self.facets_query = (
            files("data_platform_catalogue.client.graphql")
            .joinpath("facets.graphql")
            .read_text()
        )
        self.get_glossary_terms_query = (
            files("data_platform_catalogue.client.graphql")
            .joinpath("getGlossaryTerms.graphql")
            .read_text()
        )

        self.get_database_tables_query = (
            files("data_platform_catalogue.client.graphql")
            .joinpath("listContainerEntities.graphql")
            .read_text()
        )

    def search(
        self,
        query: str = "*",
        count: int = 20,
        page: str | None = None,
        result_types: Sequence[ResultType] = (
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

        start = 0 if page is None else int(page) * count

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
            raise CatalogueError("Unable to execute search query") from e

        response = response["searchAcrossEntities"]
        if response["total"] == 0:
            return SearchResponse(total_results=0, page_results=[])

        logger.debug(json.dumps(response, indent=2))

        page_results = self._parse_search_results(response)

        return SearchResponse(
            total_results=response["total"],
            page_results=page_results,
            facets=self._parse_facets(response.get("facets", [])),
        )

    def _parse_search_results(self, response):
        page_results = []
        for result in response["searchResults"]:
            entity = result["entity"]
            entity_type = entity["type"]
            matched_fields = self._get_matched_fields(result=result)

            if entity_type == "DATASET":
                page_results.append(
                    self._parse_result(entity, matched_fields, ResultType.TABLE)
                )
            elif entity_type == "CHART":
                page_results.append(
                    self._parse_result(entity, matched_fields, ResultType.CHART)
                )
            elif entity_type == "CONTAINER":
                page_results.append(self._parse_container(entity, matched_fields))
            else:
                raise ValueError(f"Unexpected entity type: {entity_type}")

        return page_results

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
        result_types: Sequence[ResultType] = (ResultType.TABLE,),
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
            raise CatalogueError("Unable to execute facets query") from e

        response = response["aggregateAcrossEntities"]
        return self._parse_facets(response.get("facets", []))

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
            raise CatalogueError("Unable to execute listDatabaseEntities query") from e

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
                page_results.append(
                    self._parse_result(entity, matched_fields, ResultType.TABLE)
                )
            else:
                raise ValueError(f"Unexpected entity type: {entity_type}")
        return page_results

    def _map_result_types(self, result_types: Sequence[ResultType]):
        """
        Map result types to Datahub EntityTypes
        """
        types = []
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
        result = [
            {"field": filter.filter_name, "values": filter.included_values}
            for filter in filters
        ]
        return result

    def _parse_result(
        self, entity: dict[str, Any], matches, result_type: ResultType
    ) -> SearchResult:
        """
        Map a dataset entity to a SearchResult
        """
        owner = parse_owner(entity)
        properties, custom_properties = parse_properties(entity)
        tags = parse_tags(entity)
        last_modified = parse_last_modified(entity)
        name, display_name, qualified_name = parse_names(entity, properties)

        relations = parse_relations(
            RelationshipType.PARENT, entity.get("relationships", {})
        )
        domain = parse_domain(entity)

        metadata = {
            "owner": owner.display_name,
            "owner_email": owner.email,
            "total_parents": entity.get("relationships", {}).get("total", 0),
            "parents": relations[RelationshipType.PARENT],
            "domain_name": domain.display_name,
            "domain_id": domain.urn,
            "entity_types": self._parse_types_and_sub_types(entity, "Dataset"),
        }

        metadata.update(custom_properties.usage_restrictions.model_dump())
        metadata.update(custom_properties.access_information.model_dump())
        metadata.update(custom_properties.data_summary.model_dump())

        _, modified = parse_created_and_modified(properties)

        return SearchResult(
            urn=entity["urn"],
            result_type=result_type,
            matches=matches,
            name=name,
            display_name=display_name,
            fully_qualified_name=qualified_name,
            description=properties.get("description", ""),
            metadata=metadata,
            tags=[tag_str.display_name for tag_str in tags],
            last_modified=modified or last_modified,
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
        properties, _ = parse_properties(entity)
        metadata = {"parentNodes": entity["parentNodes"]["nodes"]}
        name, display_name, qualified_name = parse_names(entity, properties)

        return SearchResult(
            urn=entity["urn"],
            result_type=ResultType.GLOSSARY_TERM,
            matches={},
            name=name,
            display_name=display_name,
            fully_qualified_name=qualified_name,
            description=properties.get("description", ""),
            metadata=metadata,
            tags=[],
            last_modified=None,
        )

    def get_glossary_terms(self, count: int = 1000) -> SearchResponse:
        "Get some number of glossary terms from DataHub"
        variables = {"count": count}
        try:
            response = self.graph.execute_graphql(
                self.get_glossary_terms_query, variables
            )
        except GraphError as e:
            raise CatalogueError("Unable to execute getGlossaryTerms query") from e

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
        last_modified = parse_last_modified(entity)
        properties, custom_properties = parse_properties(entity)
        domain = parse_domain(entity)
        owner = parse_owner(entity)
        name, display_name, qualified_name = parse_names(entity, properties)

        metadata = {
            "owner": owner.display_name,
            "owner_email": owner.email,
            "domain_name": domain.display_name,
            "domain_id": domain.urn,
            "entity_types": self._parse_types_and_sub_types(entity, "Container"),
        }

        metadata.update(custom_properties.usage_restrictions.model_dump())
        metadata.update(custom_properties.access_information.model_dump())
        metadata.update(custom_properties.data_summary.model_dump())
        metadata.update(custom_properties)

        return SearchResult(
            urn=entity["urn"],
            result_type=ResultType.DATABASE,
            matches=matches,
            name=name,
            fully_qualified_name=qualified_name,
            display_name=display_name,
            description=properties.get("description", ""),
            metadata=metadata,
            tags=[tag.display_name for tag in tags],
            last_modified=last_modified,
        )

    def _parse_types_and_sub_types(self, entity: dict, entity_type: str) -> dict:
        entity_sub_type = (
            entity.get("subTypes", {}).get("typeNames", [entity_type])
            if entity.get("subTypes") is not None
            else [entity_type]
        )
        return {"entity_type": entity_type, "entity_sub_types": entity_sub_type}
