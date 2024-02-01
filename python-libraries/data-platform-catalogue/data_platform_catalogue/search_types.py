from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any


class ResultType(Enum):
    DATA_PRODUCT = auto()
    TABLE = auto()


@dataclass
class MultiSelectFilter:
    """
    Values to filter the result set by
    """

    filter_name: str
    included_values: list[Any]


@dataclass
class SortOption:
    """Set the search result sorting."""

    field: str
    ascending: bool = True

    def format(self):
        return {
            "sortCriterion": {
                "field": self.field,
                "sortOrder": "ASCENDING" if self.ascending else "DESCENDING",
            }
        }


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
class SearchFacets:
    facets: dict[str, list[FacetOption]] = field(default_factory=dict)

    def options(self, field_name) -> list[FacetOption]:
        """
        Return a list of FacetOptions to display in a search facet.
        Each option includes label, value and count.
        Returns an empty list if there are no options to display.
        """
        return self.facets.get(field_name, [])

    def labels(self, field_name) -> list[str]:
        """
        Return a list of labels to display in a search facet.
        """
        return [f.label for f in self.options(field_name)]

    def lookup_label(self, field_name, label) -> FacetOption | None:
        """
        Return the FacetOption matching a particular label.
        """
        options = self.options(field_name)
        for option in options:
            if option.label == label:
                return option
        return None


@dataclass
class SearchResponse:
    total_results: int
    page_results: list[SearchResult]
    facets: SearchFacets = field(default_factory=SearchFacets)
