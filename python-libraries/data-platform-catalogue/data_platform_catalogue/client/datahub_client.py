import json
import logging
from importlib.resources import files
from typing import Sequence

from data_platform_catalogue.client.exceptions import (
    AspectDoesNotExist,
    CatalogueError,
    EntityDoesNotExist,
    InvalidDomain,
    ReferencedEntityMissing,
)
from data_platform_catalogue.client.graphql_helpers import (
    parse_columns,
    parse_created_and_modified,
    parse_domain,
    parse_names,
    parse_owner,
    parse_properties,
    parse_relations,
    parse_tags,
)
from data_platform_catalogue.client.search import SearchClient
from data_platform_catalogue.entities import (
    Chart,
    CustomEntityProperties,
    Database,
    EntityRef,
    Governance,
    OwnerRef,
    RelationshipType,
    Table,
)
from data_platform_catalogue.search_types import (
    MultiSelectFilter,
    ResultType,
    SearchFacets,
    SearchResponse,
    SortOption,
)
from datahub.emitter import mce_builder
from datahub.emitter.mcp import MetadataChangeProposalWrapper
from datahub.ingestion.graph.client import DatahubClientConfig, DataHubGraph
from datahub.ingestion.source.common.subtypes import (
    DatasetContainerSubTypes,
    DatasetSubTypes,
)
from datahub.metadata import schema_classes
from datahub.metadata.com.linkedin.pegasus2avro.common import DataPlatformInstance
from datahub.metadata.schema_classes import (
    ChangeTypeClass,
    ContainerClass,
    ContainerPropertiesClass,
    DatasetPropertiesClass,
    DomainPropertiesClass,
    DomainsClass,
    OtherSchemaClass,
    SchemaFieldClass,
    SchemaFieldDataTypeClass,
    SchemaMetadataClass,
    SubTypesClass,
)

logger = logging.getLogger(__name__)


DATAHUB_DATA_TYPE_MAPPING = {
    "boolean": schema_classes.BooleanTypeClass(),
    "tinyint": schema_classes.NumberTypeClass(),
    "smallint": schema_classes.NumberTypeClass(),
    "int": schema_classes.NumberTypeClass(),
    "integer": schema_classes.NumberTypeClass(),
    "bigint": schema_classes.NumberTypeClass(),
    "double": schema_classes.NumberTypeClass(),
    "float": schema_classes.NumberTypeClass(),
    "decimal": schema_classes.NumberTypeClass(),
    "char": schema_classes.StringTypeClass(),
    "varchar": schema_classes.StringTypeClass(),
    "string": schema_classes.StringTypeClass(),
    "date": schema_classes.DateTypeClass(),
    "timestamp": schema_classes.TimeTypeClass(),
}


class DataHubCatalogueClient:
    """Client for pushing metadata to the DataHub catalogue.

    Tables in the DataHub catalogue are arranged into the following hierarchy:
    DataPlatform -> Dataset

    This client uses the General Metadata Service (GMS, https://datahubproject.io/docs/what/gms/)
    of DataHub to create and update metadata within DataHub. This is implemented in the
    python SDK as the 'python emitter' - https://datahubproject.io/docs/metadata-ingestion/as-a-library.

    If there is a problem communicating with the catalogue, methods will raise an
    instance of CatalogueError.
    """

    def __init__(self, jwt_token, api_url: str, graph=None):
        """Create a connection to the DataHub GMS endpoint for class methods to use.

        Args:
            jwt_token: client token for interacting with the provided DataHub instance.
            api_url (str, optional): GMS endpoint for the DataHub instance for the client object.
        """
        if api_url.endswith("/"):
            api_url = api_url[:-1]
        if api_url.endswith("/api/gms") or api_url.endswith(":8080"):
            self.gms_endpoint = api_url
        elif api_url.endswith("/api"):
            self.gms_endpoint = api_url + "/gms"
        else:
            raise CatalogueError("api_url is incorrectly formatted")

        self.server_config = DatahubClientConfig(
            server=self.gms_endpoint, token=jwt_token
        )
        self.graph = graph or DataHubGraph(self.server_config)
        self.search_client = SearchClient(self.graph)

        self.dataset_query = (
            files("data_platform_catalogue.client.graphql")
            .joinpath("getDatasetDetails.graphql")
            .read_text()
        )
        self.chart_query = (
            files("data_platform_catalogue.client.graphql")
            .joinpath("getChartDetails.graphql")
            .read_text()
        )

    def check_entity_exists_by_urn(self, urn: str | None):
        if urn is not None:
            exists = self.graph.exists(entity_urn=urn)
        else:
            exists = False

        return exists

    def create_domain(
        self, domain: str, description: str = "", parent_domain: str | None = None
    ) -> str:
        """Create a Domain, a logical collection of entities

        Args:
            domain (str): name of the new Domain
            description (str, optional): Description of the new Domain. Defaults to "".
            parent_domain (str | None, optional): Declared child relationship to existing Domains.
              Defaults to None.

        Returns:
            str: urn of the created Domain
        """
        domain_properties = DomainPropertiesClass(
            name=domain, description=description, parentDomain=parent_domain
        )

        domain_urn = mce_builder.make_domain_urn(domain=domain)

        metadata_event = MetadataChangeProposalWrapper(
            entityType="domain",
            changeType=ChangeTypeClass.UPSERT,
            entityUrn=domain_urn,
            aspect=domain_properties,
        )
        self.graph.emit(metadata_event)

        return domain_urn

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
        return self.search_client.search(
            query=query,
            count=count,
            page=page,
            result_types=result_types,
            filters=filters,
            sort=sort,
        )

    def search_facets(
        self,
        query: str = "*",
        result_types: Sequence[ResultType] = (
            ResultType.TABLE,
            ResultType.CHART,
        ),
        filters: Sequence[MultiSelectFilter] = (),
    ) -> SearchFacets:
        """
        Returns facets that can be used to filter the search results.
        """
        return self.search_client.search_facets(
            query=query, result_types=result_types, filters=filters
        )

    def get_glossary_terms(self, count: int = 1000) -> SearchResponse:
        """Wraps the client's glossary terms query"""
        return self.search_client.get_glossary_terms(count)

    def get_table_details(self, urn) -> Table:
        if self.check_entity_exists_by_urn(urn):
            response = self.graph.execute_graphql(self.dataset_query, {"urn": urn})[
                "dataset"
            ]
            platform_name = response["platform"]["name"]
            properties, custom_properties = parse_properties(response)
            columns = parse_columns(response)
            domain = parse_domain(response)
            owner = parse_owner(response)
            tags = parse_tags(response)
            created, modified = parse_created_and_modified(properties)
            name, display_name, qualified_name = parse_names(response, properties)

            # A dataset can't have multiple parents, but if we did
            # start to use in that we'd need to change this
            if response["container_relations"]["total"] > 0:
                relations = parse_relations(
                    RelationshipType.PARENT, response["container_relations"]
                )
            else:
                relations = {}
            return Table(
                urn=None,
                display_name=display_name,
                name=name,
                fully_qualified_name=qualified_name,
                description=properties.get("description", ""),
                relationships=relations,
                domain=domain,
                governance=Governance(
                    data_owner=owner,
                    data_stewards=[owner],
                ),
                tags=tags,
                last_modified=modified,
                created=created,
                column_details=columns,
                custom_properties=custom_properties,
                platform=EntityRef(display_name=platform_name, urn=platform_name),
            )
        raise EntityDoesNotExist(f"Table with urn: {urn} does not exist")

    def get_chart_details(self, urn) -> Chart:
        if self.check_entity_exists_by_urn(urn):
            response = self.graph.execute_graphql(self.chart_query, {"urn": urn})[
                "chart"
            ]
            platform_name = response["platform"]["name"]
            properties, custom_properties = parse_properties(response)
            domain = parse_domain(response)
            owner = parse_owner(response)
            tags = parse_tags(response)
            name, display_name, qualified_name = parse_names(response, properties)

            return Chart(
                urn=urn,
                external_url=properties.get("externalUrl", ""),
                description=properties.get("description", ""),
                name=name,
                display_name=display_name,
                fully_qualified_name=qualified_name,
                domain=domain,
                governance=Governance(
                    data_owner=owner,
                    data_stewards=[
                        OwnerRef(
                            display_name="", email="Contact email for the user", urn=""
                        )
                    ],
                ),
                tags=tags,
                platform=EntityRef(display_name=platform_name, urn=platform_name),
                custom_properties=custom_properties,
            )

        raise EntityDoesNotExist(f"Chart with urn: {urn} does not exist")

    # to expand on and replace `list_database_tables` will need new graphql query i expect
    # but will be more equivelent to the get chart and table details methods.
    def get_database_details(self, urn: str) -> Database:
        raise NotImplementedError

    def upsert_table(self, table: Table) -> str:
        """Define a table. Must belong to a domain."""
        parent_relationships = table.relationships.get(RelationshipType.PARENT, [])
        if not parent_relationships:
            raise ValueError("A parent entity needs to be included in relationships")

        parent_name = table.relationships[RelationshipType.PARENT][0].display_name
        fully_qualified_name = generate_fqn(
            parent_name=parent_name, dataset_name=table.name
        )

        dataset_urn = mce_builder.make_dataset_urn(
            platform=table.platform.display_name,
            name=fully_qualified_name,
            env="PROD",
        )
        # jscpd:ignore-start
        dataset_properties = DatasetPropertiesClass(
            name=table.name,
            qualifiedName=fully_qualified_name,
            description=table.description,
            customProperties=self._get_custom_property_key_value_pairs(
                table.custom_properties
            ),
        )

        metadata_event = MetadataChangeProposalWrapper(
            entityUrn=dataset_urn,
            aspect=dataset_properties,
        )
        self.graph.emit(metadata_event)

        dataset_schema_properties = SchemaMetadataClass(
            schemaName=table.name,
            platform=table.platform.urn,
            version=1,
            hash="",
            platformSchema=OtherSchemaClass(rawSchema=""),
            fields=[
                SchemaFieldClass(
                    fieldPath=f"{column.name}",
                    type=SchemaFieldDataTypeClass(
                        type=DATAHUB_DATA_TYPE_MAPPING[column.type]  # type: ignore
                    ),
                    nativeDataType=column.type,
                    description=column.description,
                )
                for column in table.column_details
            ],
        )

        metadata_event = MetadataChangeProposalWrapper(
            entityType="dataset",
            changeType=ChangeTypeClass.UPSERT,
            entityUrn=dataset_urn,
            aspect=dataset_schema_properties,
        )
        self.graph.emit(metadata_event)

        # set dataset type to table
        metadata_event = MetadataChangeProposalWrapper(
            entityUrn=dataset_urn,
            aspect=SubTypesClass(typeNames=[DatasetSubTypes.TABLE]),
        )

        self.graph.emit(metadata_event)

        if table.tags:
            tags_to_add = mce_builder.make_global_tag_aspect_with_tag_list(
                tags=[str(tag.display_name) for tag in table.tags]
            )
            event: MetadataChangeProposalWrapper = MetadataChangeProposalWrapper(
                entityType="dataset",
                changeType=ChangeTypeClass.UPSERT,
                entityUrn=dataset_urn,
                aspect=tags_to_add,
            )
            self.graph.emit(event)
        # jscpd:ignore-end

        database_urn = table.relationships[RelationshipType.PARENT][0].urn

        database_exists = self.check_entity_exists_by_urn(urn=database_urn)

        if not database_exists:
            raise ReferencedEntityMissing(
                f"Database referenced by urn {database_urn} does not exist"
            )

        # add dataset to database
        metadata_event = MetadataChangeProposalWrapper(
            entityUrn=dataset_urn,
            aspect=ContainerClass(container=database_urn),
        )

        self.graph.emit(metadata_event)

        # add domain to table - tables inherit the domain of parent database if not given
        if table.domain:
            domain_urn = self.graph.get_domain_urn_by_name(
                domain_name=table.domain.display_name
            )
        else:
            domain_aspect = self.graph.get_aspect(
                entity_urn=database_urn, aspect_type=DomainsClass
            )
            if not domain_aspect:
                raise AspectDoesNotExist(
                    f"Aspect `domains` does not exist for entity with urn {database_urn}"
                )
            domain_urn = domain_aspect.domains[0]

        domain_exists = self.check_entity_exists_by_urn(domain_urn)
        if not domain_exists:
            raise InvalidDomain(
                f"{table.domain} does not exist in datahub - please align data to an existing domain"
            )

        if domain_urn is not None:
            table_domain = DomainsClass(domains=[domain_urn])
            metadata_event = MetadataChangeProposalWrapper(
                entityType="dataset",
                changeType=ChangeTypeClass.UPSERT,
                entityUrn=dataset_urn,
                aspect=table_domain,
            )

            self.graph.emit(metadata_event)

        return dataset_urn

    def upsert_chart(self, chart: Chart) -> str:
        raise NotImplementedError

    def upsert_database(self, database: Database):
        """
        Define a database. Must belong to a domain
        """
        name = database.name
        description = database.description

        database_urn = "urn:li:container:" + "".join(name.split())

        domain = database.domain
        domain_urn = self.graph.get_domain_urn_by_name(domain_name=domain.display_name)

        # domains are to be controlled and limited so we dont want to create one
        # when it doesn't exist
        if not self.check_entity_exists_by_urn(domain_urn):
            raise InvalidDomain(
                f"{domain} does not exist in datahub - please align data to an existing domain"
            )

        database_domain = DomainsClass(domains=[domain_urn])  # type: ignore

        metadata_event = MetadataChangeProposalWrapper(
            entityType="container",
            changeType=ChangeTypeClass.UPSERT,
            entityUrn=database_urn,
            aspect=database_domain,
        )
        self.graph.emit(metadata_event)
        logger.info(f"Database {name} associated with domain {domain}")

        database_properties = ContainerPropertiesClass(
            customProperties=self._get_custom_property_key_value_pairs(
                database.custom_properties
            ),
            description=description,
            name=name,
        )
        metadata_event = MetadataChangeProposalWrapper(
            entityType="container",
            changeType=ChangeTypeClass.UPSERT,
            entityUrn=database_urn,
            aspect=database_properties,
        )
        self.graph.emit(metadata_event)
        logger.info(f"Properties updated for Database {name} ")

        # set platform
        metadata_event = MetadataChangeProposalWrapper(
            entityUrn=database_urn,
            aspect=DataPlatformInstance(
                platform=database.platform.urn,
            ),
        )
        self.graph.emit(metadata_event)
        logger.info(f"Platform updated for Database {name} ")

        # container type update
        metadata_event = MetadataChangeProposalWrapper(
            entityUrn=database_urn,
            aspect=SubTypesClass(typeNames=[DatasetContainerSubTypes.DATABASE]),
        )
        self.graph.emit(metadata_event)
        logger.info(f"Type updated for Database {name} ")

        return database_urn

    def list_database_tables(self, urn: str, count: int) -> SearchResponse:
        """Wraps the client's listDatabaseEntities query"""
        return self.search_client.list_database_tables(urn=urn, count=count)

    def _get_custom_property_key_value_pairs(
        self,
        custom_properties: CustomEntityProperties,
    ) -> dict:
        """
        get each custom property as an unnested key/value pair.
        we cannot push nested structures to datahub custom properties
        """
        custom_properties_dict = json.loads(
            custom_properties.model_dump_json(), parse_int=str
        )
        custom_properties_unnested = self._flatten_dict(custom_properties_dict)
        custom_properties_unnested_all_string_values = {
            key: str(value) if value is not None else ""
            for key, value in custom_properties_unnested.items()
        }

        return custom_properties_unnested_all_string_values

    def _flatten_dict(self, d, custom_properties=None):
        if custom_properties is None:
            custom_properties = {}
        for key, value in d.items():
            if isinstance(value, dict):
                self._flatten_dict(dict(value.items()), custom_properties)
            else:
                custom_properties[key] = value
        return custom_properties


def generate_fqn(parent_name, dataset_name) -> str:
    """
    Generate a fully qualified name for a dataset
    """
    return f"{parent_name}.{dataset_name}"
