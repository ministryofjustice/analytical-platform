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
    def create_or_update_database_service(
        self, *args: Any, **kwargs: Any
    ):  # type: ignore[override]
        pass

    @abstractmethod
    def create_or_update_database(
        self, *args: Any, **kwargs: Any
    ):  # type: ignore[override]
        pass

    @abstractmethod
    def create_or_update_schema(self, *args: Any, **kwargs: Any):  # type: ignore[override]
        pass

    @abstractmethod
    def create_or_update_table(
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
        api_url: str = "https://catalogue.apps-tools.development.data-platform.service.justice.gov.uk/api",
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

    def create_or_update_database_service(
        self, name: str = "data-platform", display_name: str = "Data platform"
    ) -> str:
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

    def create_or_update_database(
        self, metadata: CatalogueMetadata | DataProductMetadata, service_fqn: str
    ):
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
        return self._create_or_update_entity(create_db)

    def create_or_update_schema(self, metadata: DataProductMetadata, database_fqn: str):
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
        return self._create_or_update_entity(create_schema)

    def create_or_update_table(self, metadata: TableMetadata, schema_fqn: str):
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
        return self._create_or_update_entity(create_table)

    def _create_or_update_entity(self, data) -> str:
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
    """
    Client for pushing metadata to the DataHub catalogue.

    Tables in the catalogue are arranged into the following hierarchy:
    Data Platform -> Dataset

    If there is a problem communicating with the catalogue, methods will raise an instance of
    CatalogueError.
    """

    def __init__(
        self,
        jwt_token,
        api_url: str = "https://datahub.apps-tools.development.data-platform.service.justice.gov.uk/api/gms",
    ):
        self.gms_endpoint = api_url
        self.server_config = DatahubClientConfig(
            server=self.gms_endpoint, token=jwt_token
        )
        self.graph = DataHubGraph(self.server_config)

    def create_or_update_database_service(
        self, name: str = "data-platform", display_name: str = "Data platform"
    ) -> str:
        """
        Define a DataHub 'Data Platform'.
        We have one service representing the connection to the data platform's internal
        glue catalogue.

        Returns the fully qualified name of the metadata object in the catalogue.
        """

        raise NotImplementedError

    def create_or_update_database(
        self, metadata: CatalogueMetadata | DataProductMetadata, service_fqn: str
    ):
        """
        Define a database. Not implemented for DataHub, which uses Data Platforms + Datasets only.
        """
        raise NotImplementedError

    def create_or_update_schema(self, metadata: DataProductMetadata, database_fqn: str):
        """
        Define a database. Not implemented for DataHub, which uses Data Platforms + Datasets only.
        """
        raise NotImplementedError

    def create_or_update_table(self, metadata: TableMetadata):
        """
        Define a table.
        There can be many tables per data product.
        columns are expected to be a list of dicts in the format
            {"name": "column1", "type": "string", "description": "just an example"}
        """
        dataset_schema_properties = SchemaMetadataClass(
            schemaName=metadata.name,
            platform=make_data_platform_urn("glue"),
            version=1,
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
            platform="glue", name=f"{metadata.name}", env="PROD"
        )

        metadata_event = MetadataChangeProposalWrapper(
            entityUrn=dataset_urn,
            aspect=dataset_schema_properties,
        )
        self.graph.emit(metadata_event)

        # tags
        tags_to_add = mce_builder.make_global_tag_aspect_with_tag_list(
            tags=metadata.tags
        )
        event: MetadataChangeProposalWrapper = MetadataChangeProposalWrapper(
            entityUrn=dataset_urn,
            aspect=tags_to_add,
        )
        self.graph.emit(event)

        return dataset_urn
