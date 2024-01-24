from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any


class ResultType(Enum):
    DATA_PRODUCT = auto()
    TABLE = auto()


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
