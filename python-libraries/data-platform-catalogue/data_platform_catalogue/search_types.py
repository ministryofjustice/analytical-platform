from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Literal


class ResultType(Enum):
    DATA_PRODUCT = auto()
    TABLE = auto()


@dataclass
class MultiSelectFilter:
    """
    Values to filter the result set by
    """

    filter_name: Literal["domains", "tags", "customProperties", "glossaryTerms"]
    included_values: list[Any]


@dataclass
class FacetOption:
    """
    A specific value that may be used to filter the search
    """

    value: str
    label: str
    count: int


@dataclass
class SearchResult:
    id: str
    result_type: ResultType
    name: str
    description: str = ""
    matches: dict[str, str] = field(default_factory=dict)
    metadata: dict[str, Any] = field(default_factory=dict)
    tags: list[str] = field(default_factory=list)
    last_updated: datetime | None = None


@dataclass
class SearchResponse:
    total_results: int
    page_results: list[SearchResult]
    facets: dict[
        Literal["domains", "tags", "customProperties", "glossaryTerms"],
        list[FacetOption],
    ] = field(default_factory=dict)
