import logging
from abc import ABC, abstractmethod
from typing import Sequence

from ..entities import (
    CatalogueMetadata,
    DataLocation,
    DataProductMetadata,
    TableMetadata,
)
from ..search_types import (
    MultiSelectFilter,
    ResultType,
    SearchFacets,
    SearchResponse,
    SortOption,
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
        raise NotImplementedError

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
        raise NotImplementedError

    def list_data_products(self) -> SearchResponse:
        return self.search(count=500, result_types=[ResultType.DATA_PRODUCT])
