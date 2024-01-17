import logging
from abc import ABC, abstractmethod
from enum import Enum, auto
from typing import Any

from ..entities import TableMetadata

logger = logging.getLogger(__name__)


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
