from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field

DATAHUB_DATE_FORMAT = "%Y%m%d"


class RelationshipType(Enum):
    PARENT = "PARENT"
    PLATFORM = "PLATFORM"


class EntityRef(BaseModel):
    """
    A reference to another entity in the metadata graph.
    """

    urn: str = Field(description="The identifier of the entity being linked to.")
    display_name: str = Field(
        description="Display name that can be used for link text."
    )


class ColumnRef(BaseModel):
    """
    A reference to a column in a table
    """

    name: str = Field(description="The column name as it appears in the table")
    display_name: str = Field(description="A user-friendly version of the name")
    table: EntityRef = Field(description="Reference to the table the column belongs to")


class Column(BaseModel):
    """
    A column definition in a table
    """

    name: str = Field(
        pattern=r"^[\w.]+$",
        description="The name of a column as it appears in the table.",
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
        description="References to columns in other tables", default_factory=list
    )


class OwnerRef(BaseModel):
    """
    A reference to a named individual that performs some kind of governance
    """

    display_name: str = Field(
        description="The full name of the user as it should be displayed"
    )
    email: str = Field("Contact email for the user")
    urn: str = Field("Unique identifier for the user")


class Governance(BaseModel):
    """
    Governance model for an entity or domain
    """

    data_owner: OwnerRef = Field(
        description="The senior individual responsible for the data."
    )
    data_stewards: list[OwnerRef] = Field(
        description="Experts who manage the data day-to-day."
    )


class DomainRef(BaseModel):
    """
    Reference to a domain that entities belong to
    """

    display_name: str = Field(
        description="Display name", json_schema_extra={"example": "HMPPS"}
    )
    urn: str = Field(
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
    urn: str = Field(
        description="The identifier of the tag",
        json_schema_extra={"example": "urn:li:tag:PII"},
    )


class UsageRestrictions(BaseModel):
    """
    Metadata about how entities may be used.
    """

    dpia_required: bool | None = Field(
        description="Bool for if a data privacy impact assessment (DPIA) is required to access this database",
        default=None,
    )
    dpia_location: str = Field(
        description="Where to find the DPIA document", default=""
    )


class AccessInformation(BaseModel):
    """
    Any metadata about how to access a data entity.
    The same data entity may be accessable via multiple means.
    """

    where_to_access_dataset: str = Field(
        description="User-friendly description of where the data can be accessed",
        default="",
    )
    source_dataset_name: str = Field(
        description="The name of a dataset this data was derived from", default=""
    )
    s3_location: str = Field(description="Location of the data in s3", default="")


class DataSummary(BaseModel):
    """
    Summarised information derived from the actual data.
    """

    row_count: int | str = Field(
        description="Row count when the metadata was last updated", default=""
    )


class CustomEntityProperties(BaseModel):
    """Custom entity properties not part of DataHub's entity model"""

    usage_restrictions: UsageRestrictions = Field(
        description="Limitations on how the data may be used and accessed",
        default_factory=UsageRestrictions,
    )
    access_information: AccessInformation = Field(
        description="Metadata about how to access a data entity",
        default_factory=AccessInformation,
    )
    data_summary: DataSummary = Field(
        description="Summary of data stored in this table", default_factory=DataSummary
    )


class Entity(BaseModel):
    """
    Any searchable data entity that is present in the metadata graph, which
    may be related to other entities.
    Examples include platforms, databases, tables
    """

    urn: str | None = Field(
        "Unique identifier for the entity. Relates to Datahub's urn"
    )
    display_name: str | None = Field("Display name of the entity")
    name: str = Field("Actual name of the entity in its source platform")
    fully_qualified_name: str | None = Field(
        "Fully qualified name of the entity in its source platform"
    )
    description: str = Field(
        description="Detailed description about what functional area this entity is representing, what purpose it has"
        " and business related information.",
    )
    relationships: dict[RelationshipType, list[EntityRef]] = Field(
        default={},
        description="References to related entities in the metadata graph, such as platform or parent entities",
    )
    domain: DomainRef = Field(description="The domain this entity belongs to.")
    governance: Governance = Field(description="Information about governance")
    tags: list[TagRef] = Field(
        default_factory=list,
        description="Additional tags to add.",
    )
    last_modified: Optional[datetime] = Field(
        description="When the metadata was last updated in the catalogue",
        default=None,
    )
    created: Optional[datetime] = Field(
        description="When the data entity was first created",
        default=None,
    )
    platform: EntityRef = Field(
        description="The platform that an entity should belong to, e.g. Glue, Athena, DBT. Should exist in datahub",
    )
    custom_properties: CustomEntityProperties = Field(
        description="Fields to add to DataHub custom properties",
        default_factory=CustomEntityProperties,
    )


class Database(Entity):
    """For source system databases"""


class Table(Entity):
    """A table in a database or a tabular dataset"""

    column_details: list[Column] = Field(
        description="A list of objects which relate to columns in your data, each list item will contain, a name of"
        " the column, data type of the column and description of the column."
    )


class Chart(Entity):
    """A visualisation of a dataset"""

    external_url: str = Field("URL to view the chart")


class Domain(Entity):
    """Datahub domain"""


# if __name__ == "__main__":
#     import erdantic as erd

#     erd.draw(Database, out="database.png")
#     erd.draw(Table, out="table.png")
#     erd.draw(Chart, out="chart.png")
