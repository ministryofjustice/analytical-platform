import logging
from abc import ABC, abstractmethod
from typing import Any

from ..entities import TableMetadata

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
