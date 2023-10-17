import logging

from metadata.generated.schema.api.data.createDatabase import CreateDatabaseRequest
from metadata.generated.schema.api.data.createDatabaseSchema import (
    CreateDatabaseSchemaRequest,
)
from metadata.generated.schema.api.services.createDatabaseService import (
    CreateDatabaseServiceRequest,
)
from metadata.generated.schema.entity.services.connections.database.customDatabaseConnection import (
    CustomDatabaseConnection,
)
from metadata.generated.schema.entity.services.connections.metadata.openMetadataConnection import (
    OpenMetadataConnection,
)
from metadata.generated.schema.entity.services.databaseService import (
    DatabaseConnection,
    DatabaseServiceType,
)
from metadata.generated.schema.security.client.openMetadataJWTClientConfig import (
    OpenMetadataJWTClientConfig,
)
from metadata.ingestion.ometa.ometa_api import OpenMetadata

from metadata.generated.schema.api.data.createTable import CreateTableRequest
from metadata.generated.schema.entity.data.table import (
    Column,
    DataType as OpenMetadataDataType,
)

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


class CatalogueClient:
    """
    Client for pushing metadata to the catalogue.

    Tables in the catalogue are arranged into the following hierarchy:
    DatabaseService -> Database -> Schema -> Table
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
        We have one service corresponding to the data platform itself.

        Returns the fully qualified name of the metadata object in the catalogue.
        """
        create_service = CreateDatabaseServiceRequest(
            name=name,
            displayName=display_name,
            serviceType=DatabaseServiceType.CustomDatabase,
            connection=DatabaseConnection(
                config=CustomDatabaseConnection(
                    type="CustomDatabase",
                )
            ),
        )
        return self._create_or_update_entity(create_service)

    def create_or_update_database(self, name: str, service_fqn: str):
        """
        Define a database.
        There should be one database per data product.
        """
        create_db = CreateDatabaseRequest(
            name=name,
            service=service_fqn,
        )
        return self._create_or_update_entity(create_db)

    def create_or_update_schema(self, name: str, database_fqn: str):
        """
        Define a database schema.
        We have a single schema per database.
        """
        create_schema = CreateDatabaseSchemaRequest(name=name, database=database_fqn)
        return self._create_or_update_entity(create_schema)

    def create_or_update_table(
        self, name: str, column_types: dict[str, str], schema_fqn: str
    ):
        """
        Define a table.
        A data product may have many tables.
        """
        columns = [
            Column(name=k, dataType=DATA_TYPE_MAPPING[v])
            for k, v in column_types.items()
        ]
        create_table = CreateTableRequest(
            name=name,
            databaseSchema=schema_fqn,
            columns=columns,
        )
        return self._create_or_update_entity(create_table)

    def _create_or_update_entity(self, data) -> str:
        logger.info(f"Creating database {data.json()}")
        response = self.metadata.create_or_update(data=data)
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
