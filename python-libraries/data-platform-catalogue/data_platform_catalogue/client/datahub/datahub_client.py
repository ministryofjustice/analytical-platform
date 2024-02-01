from typing import Sequence

import datahub.emitter.mce_builder as mce_builder
import datahub.metadata.schema_classes as schema_classes
from datahub.emitter.mce_builder import make_data_platform_urn
from datahub.emitter.mcp import MetadataChangeProposalWrapper
from datahub.ingestion.graph.client import DatahubClientConfig, DataHubGraph
from datahub.metadata.schema_classes import (
    ChangeTypeClass,
    DataProductAssociationClass,
    DataProductPropertiesClass,
    DatasetPropertiesClass,
    DomainPropertiesClass,
    DomainsClass,
    OtherSchemaClass,
    SchemaFieldClass,
    SchemaFieldDataTypeClass,
    SchemaMetadataClass,
)

from ...entities import (
    CatalogueMetadata,
    DataLocation,
    DataProductMetadata,
    TableMetadata,
)
from ...search_types import (
    MultiSelectFilter,
    ResultType,
    SearchFacets,
    SearchResponse,
    SortOption,
)
from ..base import BaseCatalogueClient, CatalogueError, ReferencedEntityMissing, logger
from .search import SearchClient

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


class DataHubCatalogueClient(BaseCatalogueClient):
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

    def upsert_database_service(self, platform: str = "glue", *args, **kwargs) -> str:
        """
        Define a DataHub 'Data Platform'. This is a type of connection, e.g. 'hive' or 'glue'.

        Returns the fully qualified name of the metadata object in the catalogue.
        """

        raise NotImplementedError

    def upsert_database(
        self, metadata: CatalogueMetadata | DataProductMetadata, location: DataLocation
    ) -> str:
        """
        Define a database. Not implemented for DataHub, which uses Data Platforms + Datasets only.
        """
        raise NotImplementedError

    def upsert_schema(
        self, metadata: DataProductMetadata, location: DataLocation
    ) -> str:
        """
        Define a database. Not implemented for DataHub, which uses Data Platforms + Datasets only.
        """
        raise NotImplementedError

    def create_domain(
        self, domain: str, description: str = "", parentDomain: str | None = None
    ) -> str:
        """Create a Domain, a logical collection of Data assets (Data Products).

        Args:
            metadata (DataProductMetadata): _description_
        """
        domain_properties = DomainPropertiesClass(
            name=domain, description=description, parentDomain=parentDomain
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

    def upsert_data_product(self, metadata: DataProductMetadata):
        """
        Define a data product. Must belong to a domain
        """
        metadata_dict = dict(metadata.__dict__)
        metadata_dict.pop("version")
        metadata_dict.pop("owner")
        metadata_dict.pop("tags")

        name = metadata_dict.pop("name")
        description = metadata_dict.pop("description")

        data_product_urn = "urn:li:dataProduct:" + "".join(name.split())

        if metadata.domain:
            domain = metadata_dict.pop("domain")
            domain_urn = self.graph.get_domain_urn_by_name(domain_name=domain)

            if domain_urn is None:
                logger.info(f"creating new domain {domain} for {name}")
                domain_urn = self.create_domain(domain=domain)

            data_product_domain = DomainsClass(domains=[domain_urn])
            metadata_event = MetadataChangeProposalWrapper(
                entityType="dataproduct",
                changeType=ChangeTypeClass.UPSERT,
                entityUrn=data_product_urn,
                aspect=data_product_domain,
            )
            self.graph.emit(metadata_event)
            logger.info(f"Data Product {name} associated with domain {domain}")

            data_product_properties = DataProductPropertiesClass(
                customProperties={key: str(val) for key, val in metadata_dict.items()},
                description=description,
                name=name,
            )
            metadata_event = MetadataChangeProposalWrapper(
                entityType="dataproduct",
                changeType=ChangeTypeClass.UPSERT,
                entityUrn=data_product_urn,
                aspect=data_product_properties,
            )
            self.graph.emit(metadata_event)
            logger.info(f"Properties updated for Data Product {name} ")

            return data_product_urn
        else:
            raise ReferencedEntityMissing("Data Product must belong to a Domain")

    def upsert_table(
        self,
        metadata: TableMetadata,
        location: DataLocation,
        data_product_metadata: DataProductMetadata | None = None,
    ) -> str:
        """
        Define a table (a 'dataset' in DataHub parlance), a 'collection of data'
        (https://datahubproject.io/docs/metadata-modeling/metadata-model#the-core-entities).

        There can be many tables per Data Product.

        Columns are expected to be a list of dicts in the format
            {"name": "column1", "type": "string", "description": "just an example"}

        This method creates a schemaMetadata aspect object from the metadata object
        (https://datahubproject.io/docs/generated/metamodel/entities/dataset/#schemametadata)
        together with generating a unique reference name (URN) for the dataset used by DataHub.
        These are then emitted to the rest.li api as a dataset creation/update event proposal.

        If tags are present in the metadata object, a second request is made to update the dataset
        with these tags as a separate aspect.

        Args:
            metadata (TableMetadata): metadata object.
            platform (str, optional): DataHub data platform type. Defaults to "glue".
            version (int, optional): Defaults to 1.

        Returns:
            dataset_urn: the dataset URN
        """
        if location.fully_qualified_name:
            name = f"{location.fully_qualified_name}.{metadata.name}"
        else:
            name = metadata.name

        dataset_urn = mce_builder.make_dataset_urn(
            platform=location.platform_id, name=name, env="PROD"
        )

        dataset_properties = DatasetPropertiesClass(
            description=metadata.description,
            # customProperties={"dpia_required": "yes"},
        )

        metadata_event = MetadataChangeProposalWrapper(
            entityUrn=dataset_urn,
            aspect=dataset_properties,
        )
        self.graph.emit(metadata_event)

        dataset_schema_properties = SchemaMetadataClass(
            schemaName=metadata.name,
            platform=make_data_platform_urn(platform=location.platform_id),
            version=metadata.major_version,
            hash="",
            platformSchema=OtherSchemaClass(rawSchema=""),
            fields=[
                SchemaFieldClass(
                    fieldPath=f"{column['name']}",
                    type=SchemaFieldDataTypeClass(
                        type=DATAHUB_DATA_TYPE_MAPPING[column["type"]]
                    ),
                    nativeDataType=column["type"],
                    description=column["description"],
                )
                for column in metadata.column_details
            ],
        )

        metadata_event = MetadataChangeProposalWrapper(
            entityType="dataset",
            changeType=ChangeTypeClass.UPSERT,
            entityUrn=dataset_urn,
            aspect=dataset_schema_properties,
        )
        self.graph.emit(metadata_event)

        if metadata.tags:
            tags_to_add = mce_builder.make_global_tag_aspect_with_tag_list(
                tags=metadata.tags
            )
            event: MetadataChangeProposalWrapper = MetadataChangeProposalWrapper(
                entityType="dataset",
                changeType=ChangeTypeClass.UPSERT,
                entityUrn=dataset_urn,
                aspect=tags_to_add,
            )
            self.graph.emit(event)

        if data_product_metadata is not None:
            data_product_urn = "urn:li:dataProduct:" + "".join(
                data_product_metadata.name.split()
            )
            data_product_exists = self.graph.exists(entity_urn=data_product_urn)

            if not data_product_exists:
                data_product_urn = self.upsert_data_product(
                    metadata=data_product_metadata
                )

            data_product_existing_properties = self.graph.get_aspect(
                entity_urn=data_product_urn, aspect_type=DataProductPropertiesClass
            )

            data_product_association = DataProductAssociationClass(
                destinationUrn=dataset_urn, sourceUrn=data_product_urn
            )

            if (
                data_product_existing_properties is not None
                and data_product_existing_properties.assets is not None
            ):
                assets = data_product_existing_properties.assets[::]
                assets.append(data_product_association)
            else:
                assets = [data_product_association]

            data_product_properties = DataProductPropertiesClass(assets=assets)

            metadata_event = MetadataChangeProposalWrapper(
                entityType="dataproduct",
                changeType=ChangeTypeClass.UPSERT,
                entityUrn=data_product_urn,
                aspect=data_product_properties,
            )
            self.graph.emit(metadata_event)

        return dataset_urn

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
            ResultType.DATA_PRODUCT,
            ResultType.TABLE,
        ),
        filters: Sequence[MultiSelectFilter] = (),
    ) -> SearchFacets:
        """
        Returns facets that can be used to filter the search results.
        """
        return self.search_client.search_facets(
            query=query, result_types=result_types, filters=filters
        )
