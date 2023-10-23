from dataclasses import dataclass, field


@dataclass
class CatalogueMetadata:
    name: str
    description: str
    tags: list[str] = field(default_factory=list)


@dataclass
class DataProductMetadata:
    name: str
    description: str
    version: str
    owner: str
    email: str
    retention_period_in_days: int
    domain: str
    dpia_required: bool
    tags: list[str] = field(default_factory=list)


@dataclass
class TableMetadata:
    name: str
    description: str
    column_types: dict[str, str]
    retention_period_in_days: int
    tags: list[str] = field(default_factory=list)
