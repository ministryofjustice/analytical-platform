from datetime import datetime
from enum import Enum, auto
from typing import Any

DATAHUB_DATE_FORMAT = "%Y%m%d"


from pydantic import BaseModel, Field


class DataProductStatus(Enum):
    DRAFT = auto()
    PUBLISHED = auto()
    RETIRED = auto()


class DatabaseStatus(Enum):
    PROD = auto()
    PREPROD = auto()
    DEV = auto()


class RelationshipType(Enum):
    PARENT = auto()
    PLATFORM = auto()


# Needs refining
class SecurityClassification(Enum):
    """
    Government security classification
    """

    OFFICIAL = auto()


class AssetRef(BaseModel):
    """
    A reference to another asset in the metadata graph.
    """

    id: str = Field(
        description="The identifier of the asset being linked to.",
    )
    display_name: str = Field(
        description="Display name that can be used for link text."
    )


class ColumnRef(BaseModel):
    """
    A reference to a column in a table
    """

    name: str = Field(description="The column name as it appears in the table")
    display_name: str = Field(description="A user-friendly version of the name")
    table: AssetRef = Field(description="Reference to the table the column belongs to")


class Column(BaseModel):
    """
    A column definition in a table
    """

    name: str = Field(
        pattern=r"^[a-z0-9_]+$",
        description="The name of a column as it appears in the table.",
        json_schema_extra={"pattern": r"^[a-z0-9_]+$"},
    )
    display_name: str = Field(description="A user-friendly version of the name")
    type: str = Field(
        description="The data type of the column as it appears in the table",
    )
    description: str = Field(description="A description of the column")
    nullable: bool = Field(description="Whether the field is nullable or not")
    is_primary_key: bool = Field(
        description="Whether the field is part of the primary key"
    )
    foreign_keys: list[ColumnRef] = Field(
        description="References to columns in other tables"
    )


class ContactRef(BaseModel):
    """
    A reference to a named individual that performs some kind of governance
    """

    display_name: str = Field(
        description="The full name of the user as it should be displayed"
    )
    email: str = Field("Contact email for the user")
    id: str = Field("Unique identifier for the user")


# Needs refining
class Governance(BaseModel):
    """
    Governance model for an asset or domain
    """

    data_owner: ContactRef = Field(description="")
    data_stewards: list[ContactRef] = Field(description="")


class DomainRef(BaseModel):
    """
    Reference to a domain that assets belong to
    """

    display_name: str = Field(
        description="Display name", json_schema_extra={"example": "HMPPS"}
    )
    id: str = Field(
        description="The identifier of the domain.",
        json_schema_extra={"example": "urn:li:domain:HMCTS"},
    )


class TagRef(BaseModel):
    """
    Reference to a tag
    """

    display_name: str = Field(
        description="Human friendly tag name", json_schema_extra={"example": "PII"}
    )
    id: str = Field(
        description="The identifier of the tag",
        json_schema_extra={"example": "urn:li:tag:PII"},
    )


# Needs refining
class UsageRestrictions(BaseModel):
    """
    Metadata about how assets may be used.
    """

    status: DatabaseStatus = Field(
        description="this is an enum representing the status of this version of the Data Product. Allowed values are: [draft|published|retired]. This is a metadata that communicates the overall status of the Data Product but is not reflected to the actual deployment status."
    )
    dpia_required: bool = Field(
        description="Bool for if a data privacy impact assessment (dpia) is required to access this data product",
        json_schema_extra={"example": True},
    )
    dpia_location: str | None = Field(description="")
    data_sensitivity_level: SecurityClassification = Field(
        description="", default=SecurityClassification.OFFICIAL
    )


# Needs refining
class AccessInformation(BaseModel):
    """
    Any metadata about how to access a data asset.
    The same data asset may be accessable via multiple means.
    """

    where_to_access_dataset: str = Field(
        description="User-friendly description of where the data can be accessed",
        default="",
    )
    source_dataset_name: str = Field(description="", default="")
    s3_location: str | None = Field(
        description="Location of the data in s3", default=None
    )


# Needs refining
class DataSummary(BaseModel):
    """
    Summarised information derived from the actual data.
    """

    row_count: int | None = Field(
        description="Row count when the metadata was last updated", default=None
    )


class Entity(BaseModel):
    """
    Any searchable data entity that is present in the metadata graph, which
    may be related to other entities.
    Examples include platforms, databases, tables, data products
    """

    id: str | None = Field("Unique identifier for the entity. Relates to Datahub's urn")
    display_name: str | None = Field("Display name of the entity")
    name: str = Field("Actual name of the entity in its source platform")
    fully_qualified_name: str | None = Field(
        "Fully qualified name of the entity in its source platform"
    )
    description: str = Field(
        description="Detailed description about what functional area this entity is representing, what purpose it has and business related information.",
    )
    relationships: dict[RelationshipType, list[EntityRef]] | None = Field(
        default=None,
        description="References to related entities in the metadata graph, such as platform or parent entities",
    )
    domain: DomainRef = Field(description="The domain this entity belongs to.")
    governance: Governance = Field(description="Information about governance")
    usage_restrictions: UsageRestrictions = Field(
        description="Limitations on how the data may be used and accessed"
    )
    tags: list[TagRef] = Field(
        default_factory=list,
        description="Additional tags to add.",
    )

    # Needs refining
    last_updated: datetime = Field(
        description="When the metadata was last updated in the catalogue"
    )
    first_created: datetime = Field(description="When the data entity was first created")


class Database(Entity):
    """
    For source system databases
    """

    status: DatabaseStatus = Field(
        default=DatabaseStatus.PROD,
        description="Whether this database represents production data or not",
    )


class Table(Entity):
    """
    A table in a database or a tabular dataset
    """

    column_details: list[Column] = Field(
        description="A list of objects which relate to columns in your data, each list item will contain, a name of the column, data type of the column and description of the column."
    )
    fully_qualified_name: str | None = Field(
        default=None,
        description="Fully qualified table name as it appears in the source platform, including the database",
    )
    access_information: AccessInformation = Field(
        description="Metadata about how to access the data"
    )
    data_summary: DataSummary = Field(
        description="Summary of data stored in this table"
    )


class Chart(Entity):
    """
    A visualisation of a dataset
    """

    external_url: str = Field("URL to view the chart")
    fully_qualified_name: str | None = Field(
        default=None,
        description="Fully qualified name as it appears in the source platform including the dashboard",
    )
    access_information: AccessInformation = Field(
        description="Metadata about how to access the data"
    )
    data_summary: DataSummary = Field(
        description="Summary of data stored in this table"
    )


if __name__ == "__main__":
    import erdantic as erd

    erd.draw(Database, out="database.png")
    erd.draw(Table, out="table.png")
    erd.draw(Chart, out="chart.png")
