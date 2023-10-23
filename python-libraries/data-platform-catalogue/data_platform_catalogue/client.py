import json
import logging

from http import HTTPStatus
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
from metadata.ingestion.ometa.ometa_api import OpenMetadata, APIError

from .entities import CatalogueMetadata, DataProductMetadata, TableMetadata

logger = logging.getLogger(__name__)


DATA_TYPE_MAPPING = {
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


class CatalogueError(Exception):
    """
    Base class for all errors.
    """


class ReferencedEntityMissing(CatalogueError):
    """
    A referenced entity (such as a user or tag) does not yet exist when
    attempting to create a new metadata resource in the catalogue.
    """


class CatalogueClient:
    """
    Client for pushing metadata to the catalogue.

    Tables in the catalogue are arranged into the following hierarchy:
    DatabaseService -> Database -> Schema -> Table

    If there is a problem communicating with the catalogue, methods will raise an instance of
    CatalogueError.
    """

    def __init__(
        self,
        jwt_token,
        api_uri: str = "https://catalogue.apps-tools.development.data-platform.service.justice.gov.uk/api",
    ):
        self.server_config = OpenMetadataConnection(
            hostPort=api_uri,
            securityConfig=OpenMetadataJWTClientConfig(jwtToken=jwt_token),
            authProvider="openmetadata",
        )
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

        return response["fullyQualifiedName"]

    def create_or_update_database(self, metadata: CatalogueMetadata, service_fqn: str):
        """
        Define a database.
        There should be one database per data platform catalogue.
        """
        create_db = CreateDatabaseRequest(
            name=metadata.name,
            description=metadata.description,
            tags=self._generate_tags(metadata.tags),
            service=service_fqn,
        )
        return self._create_or_update_entity(create_db)

    def create_or_update_schema(self, metadata: DataProductMetadata, database_fqn: str):
        """
        Define a database schema.
        There should be one schema per data product.
        """
        create_schema = CreateDatabaseSchemaRequest(
            name=metadata.name,
            description=metadata.description,
            owner=EntityReference(id=metadata.owner, type="user"),
            tags=self._generate_tags(metadata.tags),
            retentionPeriod=self._generate_duration(metadata.retention_period_in_days),
            database=database_fqn,
        )
        return self._create_or_update_entity(create_schema)

    def create_or_update_table(self, metadata: TableMetadata, schema_fqn: str):
        """
        Define a table.
        There can be many tables per data product.
        """
        columns = [
            Column(name=k, dataType=DATA_TYPE_MAPPING[v])
            for k, v in metadata.column_types.items()
        ]
        create_table = CreateTableRequest(
            name=metadata.name,
            description=metadata.description,
            retentionPeriod=self._generate_duration(metadata.retention_period_in_days),
            tags=self._generate_tags(metadata.tags),
            databaseSchema=schema_fqn,
            columns=columns,
        )
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

    def delete_database_service(self, fqn: str):
        """
        Delete a database service.
        """
        raise NotImplementedError

    def delete_database(self, fqn: str):
        """
        Delete a database.
        """
        raise NotImplementedError

    def delete_schema(self, fqn: str):
        """
        Delete a schema
        """
        raise NotImplementedError

    def delete_table(self, fqn: str):
        """
        Delete a table.
        """
        raise NotImplementedError

    def _generate_tags(self, tags: list[str]):
        return [
            TagLabel(
                tagFQN=tag,
                labelType=LabelType.Automated,
                source=TagSource.Classification,
                state=State.Confirmed,
            )
            for tag in tags
        ]

    def _generate_duration(self, duration_in_days: int):
        return Duration.parse_obj(f"P{duration_in_days}D")
