import json
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

from ..entities import (
    CatalogueMetadata,
    DataLocation,
    DataProductMetadata,
    TableMetadata,
)
from .base import BaseCatalogueClient, CatalogueError, ReferencedEntityMissing, logger

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

    def upsert_database(
        self, metadata: CatalogueMetadata | DataProductMetadata, location: DataLocation
    ) -> str:
        """
        Define a database.
        There should be one database per data product.
        """
        create_db = CreateDatabaseRequest(
            name=metadata.name,
            description=metadata.description,
            tags=self._generate_tags(metadata.tags),
            service=location.fully_qualified_name,
            owner=EntityReference(
                id=metadata.owner, type="user"
            ),  # pyright: ignore[reportGeneralTypeIssues]
        )
        return self._upsert_entity(create_db)

    def upsert_schema(
        self, metadata: DataProductMetadata, location: DataLocation
    ) -> str:
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
            database=location.fully_qualified_name,
        )
        return self._upsert_entity(create_schema)

    def upsert_table(
        self,
        metadata: TableMetadata,
        location: DataLocation,
        *args,
        **kwargs,
    ) -> str:
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
            databaseSchema=location.fully_qualified_name,
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
