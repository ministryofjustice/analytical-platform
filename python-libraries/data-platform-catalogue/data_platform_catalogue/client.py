import json
import logging
from abc import ABC, abstractmethod
from enum import Enum, auto
from http import HTTPStatus
from typing import Any

import datahub.emitter.mce_builder as mce_builder
import datahub.metadata.schema_classes as schema_classes
from datahub.emitter.mce_builder import make_data_platform_urn
from datahub.emitter.mcp import MetadataChangeProposalWrapper
from datahub.ingestion.graph.client import DatahubClientConfig, DataHubGraph
from datahub.metadata.schema_classes import (
    ChangeTypeClass,
    DataProductAssociationClass,
    DataProductPropertiesClass,
    DomainPropertiesClass,
    DomainsClass,
    OtherSchemaClass,
    SchemaFieldClass,
    SchemaFieldDataTypeClass,
    SchemaMetadataClass,
)
from metadata.generated.schema.api.data.createDatabase import CreateDatabaseRequest
from metadata.generated.schema.api.data.createDatabaseSchema import (
    CreateDatabaseSchemaRequest,
)
from metadata.generated.schema.api.data.createTable import CreateTableRequest
from metadata.generated.schema.entity.data.table import Column
from metadata.generated.schema.entity.data.table import DataType as OpenMetadataDataType
from metadata.generated.schema.entity.services.connections.metadata.openMetadataConnection import (
    OpenMetadataConnection,
)
from metadata.generated.schema.entity.services.databaseService import (
    DatabaseServiceType,
)
from metadata.generated.schema.entity.teams.user import User
from metadata.generated.schema.security.client.openMetadataJWTClientConfig import (
    OpenMetadataJWTClientConfig,
)
from metadata.generated.schema.type.basic import Duration
from metadata.generated.schema.type.entityReference import EntityReference
from metadata.generated.schema.type.tagLabel import (
    LabelType,
    State,
    TagLabel,
    TagSource,
)
from metadata.ingestion.ometa.ometa_api import APIError, OpenMetadata

from .entities import CatalogueMetadata, DataProductMetadata, TableMetadata

logger = logging.getLogger(__name__)


OMD_DATA_TYPE_MAPPING = {
    "boolean": OpenMetadataDataType.BOOLEAN,
    "tinyint": OpenMetadataDataType.TINYINT,
    "smallint": OpenMetadataDataType.SMALLINT,
    "int": OpenMetadataDataType.INT,
    "integer": OpenMetadataDataType.INT,
    "bigint": OpenMetadataDataType.BIGINT,
    "double": OpenMetadataDataType.DOUBLE,
    "float": OpenMetadataDataType.FLOAT,
    "decimal": OpenMetadataDataType.DECIMAL,
    "char": OpenMetadataDataType.CHAR,
    "varchar": OpenMetadataDataType.VARCHAR,
    "string": OpenMetadataDataType.STRING,
    "date": OpenMetadataDataType.DATE,
    "timestamp": OpenMetadataDataType.TIMESTAMP,
}

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


class ClientName(Enum):
    OPENMETADATA = auto()
    DATAHUB = auto()

    @classmethod
    def __contains__(cls, item):
        return item in cls.__members__.values()

    @classmethod
    def from_string(cls, string: str):
        s = ("".join(filter(str.isalpha, string))).upper()

        if "OPENMETADATA" in s:
            return cls["OPENMETADATA"]
        elif "DATAHUB" in s:
            return cls["DATAHUB"]
        else:
            raise ValueError(f"Cannot infer client name from given string: {string}")


class CatalogueError(Exception):
    """
    Base class for all errors.
    """


class ReferencedEntityMissing(CatalogueError):
    """
    A referenced entity (such as a user or tag) does not yet exist when
    attempting to create a new metadata resource in the catalogue.
    """


class BaseCatalogueClient(ABC):
    @abstractmethod
    def upsert_database_service(
        self, *args: Any, **kwargs: Any
    ):  # type: ignore[override]
        pass

    @abstractmethod
    def upsert_database(self, *args: Any, **kwargs: Any):  # type: ignore[override]
        pass

    @abstractmethod
    def upsert_schema(self, *args: Any, **kwargs: Any):  # type: ignore[override]
        pass

    @abstractmethod
    def upsert_table(
        self, metadata: TableMetadata, *args: Any, **kwargs: Any
    ):  # type: ignore[override]
        pass

    def delete_database_service(self, *args: Any, **kwargs: Any):  # type: ignore[override]
        """
        Delete a database service.
        """
        raise NotImplementedError

    def delete_database(self, *args: Any, **kwargs: Any):  # type: ignore[override]
        """
        Delete a database.
        """
        raise NotImplementedError

    def delete_schema(self, *args: Any, **kwargs: Any):  # type: ignore[override]
        """
        Delete a schema.
        """
        raise NotImplementedError

    def delete_table(self, *args: Any, **kwargs: Any):  # type: ignore[override]
        """
        Delete a table.
        """
        raise NotImplementedError


class OpenMetadataCatalogueClient(BaseCatalogueClient):
    """
    Client for pushing metadata to the OpenMetadata catalogue.

    Tables in the catalogue are arranged into the following hierarchy:
    DatabaseService -> Database -> Schema -> Table

    If there is a problem communicating with the catalogue, methods will raise an instance of
    CatalogueError.
    """

    def __init__(
        self,
        jwt_token,
        api_url: str,
    ):
        self.server_config = OpenMetadataConnection(
            hostPort=api_url,
            securityConfig=OpenMetadataJWTClientConfig(jwtToken=jwt_token),
            authProvider="openmetadata",
        )  # pyright: ignore[reportGeneralTypeIssues]
        self.metadata = OpenMetadata(self.server_config)

    def is_healthy(self) -> bool:
        """
        Ping the catalogue health check and return True if healthy.
        """
        return self.metadata.health_check()

    def upsert_database_service(
        self, name: str = "data-platform", display_name: str = "Data platform"
    ) -> str:  # type: ignore[override]
        """
        Define a database service.
        We have one service representing the connection to the data platform's internal
        glue catalogue.

        Returns the fully qualified name of the metadata object in the catalogue.
        """
        # Directly pass JSON as a workaround because in metadata.create_or_update won't let us pass
        # an empty connection config if serviceType = Glue.
        # This workaround can be removed when we update to OpenMetadata 1.2.0.
        service = {
            "name": name,
            "displayName": display_name,
            "serviceType": DatabaseServiceType.Glue.value,
            "connection": {"config": {}},
        }

        logger.info(f"Creating {service}")

        response = self.metadata.client.put(
            "/services/databaseServices", data=json.dumps(service)
        )
        if response is not None:
            return response["fullyQualifiedName"]
        else:
            raise ReferencedEntityMissing

    def upsert_database(
        self, metadata: CatalogueMetadata | DataProductMetadata, service_fqn: str
    ):  # type: ignore[override]
        """
        Define a database.
        There should be one database per data product.
        """
        create_db = CreateDatabaseRequest(
            name=metadata.name,
            description=metadata.description,
            tags=self._generate_tags(metadata.tags),
            service=service_fqn,
            owner=EntityReference(
                id=metadata.owner, type="user"
            ),  # pyright: ignore[reportGeneralTypeIssues]
        )
        return self._upsert_entity(create_db)

    def upsert_schema(self, metadata: DataProductMetadata, database_fqn: str):  # type: ignore[override]
        """
        Define a database schema.
        There should be one schema per data product and for now flexibility is retained
        and metadata is of type DataProductMetadata but we'd expect a uniform name and
        description for each data product, e.g:
            name="Tables", description="All the tables contained within {data_product_name}"
        """
        create_schema = CreateDatabaseSchemaRequest(
            name=metadata.name,
            description=metadata.description,
            owner=EntityReference(
                id=metadata.owner, type="user"
            ),  # pyright: ignore[reportGeneralTypeIssues]
            tags=self._generate_tags(metadata.tags),
            retentionPeriod=self._generate_duration(metadata.retention_period_in_days),
            database=database_fqn,
        )
        return self._upsert_entity(create_schema)

    def upsert_table(self, metadata: TableMetadata, schema_fqn: str):  # type: ignore[override]
        """
        Define a table.
        There can be many tables per data product.
        columns are expected to be a list of dicts in the format
            {"name": "column1", "type": "string", "description": "just an example"}
        """
        columns = [
            Column(
                name=column["name"],
                dataType=OMD_DATA_TYPE_MAPPING[column["type"]],
                description=column["description"],
            )  # pyright: ignore[reportGeneralTypeIssues]
            # pyright is ignoring field(None,x)
            for column in metadata.column_details
        ]
        create_table = CreateTableRequest(
            name=metadata.name,
            description=metadata.description,
            retentionPeriod=self._generate_duration(metadata.retention_period_in_days),
            tags=self._generate_tags(metadata.tags),
            databaseSchema=schema_fqn,
            columns=columns,
        )  # pyright: ignore[reportGeneralTypeIssues]
        return self._upsert_entity(create_table)

    def _upsert_entity(self, data) -> str:
        logger.info(f"Creating {data.json()}")

        try:
            response = self.metadata.create_or_update(data=data)
        except APIError as exception:
            if exception.status_code == HTTPStatus.NOT_FOUND:
                raise ReferencedEntityMissing from exception
            else:
                raise CatalogueError from exception
        except Exception as exception:
            raise CatalogueError from exception

        return response.dict()["fullyQualifiedName"]

    def get_user_id(self, user_email: str):
        """
        returns the user id from openmetadata when given a user's email
        """
        username = user_email.split("@")[0]
        user = self.metadata.get_by_name(entity=User, fqn=username)
        if user is not None:
            return user.id
        else:
            raise ReferencedEntityMissing

    def _generate_tags(self, tags: list[str]):
        # TODO? update using the sdk logic:
        # https://docs.open-metadata.org/v1.2.x/sdk/python/ingestion/tags#6-creating-the-classification
        return [
            TagLabel(
                tagFQN=tag,
                labelType=LabelType.Automated,
                source=TagSource.Classification,
                state=State.Confirmed,
            )  # pyright: ignore[reportGeneralTypeIssues]
            for tag in tags
        ]

    def _generate_duration(self, duration_in_days: int | None):
        if duration_in_days is None:
            return None
        else:
            return Duration.parse_obj(f"P{duration_in_days}D")


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

    def upsert_database_service(
        self, platform: str = "glue"
    ) -> str:  # type: ignore[override]
        """
        Define a DataHub 'Data Platform'. This is a type of connection, e.g. 'hive' or 'glue'.

        Returns the fully qualified name of the metadata object in the catalogue.
        """

        raise NotImplementedError

    def upsert_database(
        self, metadata: CatalogueMetadata | DataProductMetadata, service_fqn: str
    ):  # type: ignore[override]
        """
        Define a database. Not implemented for DataHub, which uses Data Platforms + Datasets only.
        """
        raise NotImplementedError

    def upsert_schema(self, metadata: DataProductMetadata, database_fqn: str):  # type: ignore[override]
        """
        Define a database. Not implemented for DataHub, which uses Data Platforms + Datasets only.
        """
        raise NotImplementedError

    def create_domain(
        self, domain: str, description: str = "", parentDomain: str | None = None
    ):
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
        metadata_dict = vars(metadata)
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

    def upsert_table(  # type: ignore[override]
        self,
        metadata: TableMetadata,
        data_product_metadata: DataProductMetadata | None = None,
        platform: str = "glue",
        version: int = 1,
    ):
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
        dataset_schema_properties = SchemaMetadataClass(
            schemaName=metadata.name,
            platform=make_data_platform_urn(platform=platform),
            version=version,
            hash="",
            platformSchema=OtherSchemaClass(rawSchema="__insert raw schema here__"),
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

        dataset_urn = mce_builder.make_dataset_urn(
            platform=platform, name=f"{metadata.name}", env="PROD"
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
                data_product_existing_properties.assets  # pyright: ignore[reportOptionalMemberAccess]
                is not None
            ):
                assets = data_product_existing_properties.assets.append(  # pyright: ignore[reportOptionalMemberAccess]
                    data_product_association
                )
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
