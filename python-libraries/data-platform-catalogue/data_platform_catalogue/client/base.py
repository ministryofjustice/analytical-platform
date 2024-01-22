import logging
from abc import ABC, abstractmethod

from ..entities import (
    CatalogueMetadata,
    DataLocation,
    DataProductMetadata,
    TableMetadata,
)

logger = logging.getLogger(__name__)


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
        self, platform: str = "glue", display_name: str = "Data platform"
    ) -> str:
        pass

    @abstractmethod
    def upsert_database(
        self,
        metadata: CatalogueMetadata | DataProductMetadata,
        location: DataLocation,
    ) -> str:
        pass

    @abstractmethod
    def upsert_schema(
        self, metadata: DataProductMetadata, location: DataLocation
    ) -> str:
        pass

    @abstractmethod
    def upsert_table(
        self,
        metadata: TableMetadata,
        location: DataLocation,
        data_product_metadata: DataProductMetadata | None = None,
    ) -> str:
        pass
