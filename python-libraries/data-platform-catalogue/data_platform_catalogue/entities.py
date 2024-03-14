from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any

DATAHUB_DATE_FORMAT = "%Y%m%d"


@dataclass
class CatalogueMetadata:
    name: str
    description: str
    owner: str
    tags: list[str] = field(default_factory=list)


@dataclass
class DataLocation:
    """
    A representation of where the data can be found
    (in our case, glue/athena)
    """

    fully_qualified_name: str
    platform_type: str = "glue"
    platform_id: str = "glue"


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


@dataclass
class RelatedEntity:
    id: str
    name: str


@dataclass
class DataProductMetadata:
    name: str
    description: str
    version: str
    owner: str
    owner_display_name: str
    maintainer: str | None
    maintainer_display_name: str | None
    email: str
    retention_period_in_days: int
    domain: str
    subdomain: str | None
    dpia_required: bool
    dpia_location: str | None
    last_updated: datetime
    creation_date: datetime
    s3_location: str | None
    status: DataProductStatus = DataProductStatus.DRAFT
    tags: list[str] = field(default_factory=list)

    @staticmethod
    def from_data_product_metadata_dict(metadata: dict, version, owner_id: str):
        """
        Expects a dict containing data product metatdata information as per the
        required fields in the json schema at
        https://github.com/ministryofjustice/modernisation-platform-environments/tree/main/terraform/environments/data-platform/data-product-metadata-json-schema

        Then populates a DataProductMetadata object with the given data.
        """
        new_metadata = DataProductMetadata(
            name=metadata["name"],
            description=metadata["description"],
            version=version,
            owner=owner_id,
            owner_display_name=metadata["dataProductOwnerDisplayName"],
            maintainer=metadata.get("dataProductMaintainer"),
            maintainer_display_name=metadata.get("dataProductMaintainerDisplayName"),
            email=metadata["email"],
            status=DataProductStatus[metadata["status"]],
            retention_period_in_days=metadata["retentionPeriod"],
            domain=metadata["domain"],
            subdomain=metadata.get("subdomain"),
            dpia_required=metadata["dpiaRequired"],
            dpia_location=metadata.get("dpiaLocation"),
            last_updated=datetime.strptime(
                metadata["lastUpdated"], DATAHUB_DATE_FORMAT
            ),
            creation_date=datetime.strptime(
                metadata["creationDate"], DATAHUB_DATE_FORMAT
            ),
            s3_location=metadata.get("s3Location"),
            tags=metadata.get("tags", []),
        )

        return new_metadata


class SecurityClassification(Enum):
    OFFICIAL = auto()


@dataclass
class TableMetadata:
    name: str
    description: str
    column_details: list
    retention_period_in_days: int | None
    domain: str | None = None
    parent_entity_name: str | None = None
    relationships: dict[RelationshipType, list[RelatedEntity]] | None = None
    source_dataset_name: str = ""
    where_to_access_dataset: str = ""
    fully_qualified_name: str | None = None
    data_sensitivity_level: SecurityClassification = SecurityClassification.OFFICIAL
    tags: list[str] = field(default_factory=list)
    major_version: int = 1
    row_count: int | None = None
    owner: str = ""
    owner_email: str = ""
    last_updated: datetime | None = None
    first_created: datetime | None = None

    @staticmethod
    def from_data_product_schema_dict(
        metadata: dict[str, Any], table_name, retention_period: int | None = None
    ):
        """
        Expects a dict containing data product table schema information as per the
        required fields in the json schema at
        https://github.com/ministryofjustice/modernisation-platform-environments/tree/main/terraform/environments/data-platform/data-product-table-schema-json-schema

        and should be passed table name and optionally a retention period

        Then populates a TableMetadata object with the given data.
        """

        new_metadata = TableMetadata(
            name=table_name,
            description=metadata["tableDescription"],
            column_details=metadata["columns"],
            retention_period_in_days=retention_period,
            source_dataset_name=metadata.get("sourceDatasetName", ""),
            where_to_access_dataset=metadata.get("sourceDatasetLocation", ""),
            data_sensitivity_level=SecurityClassification[
                metadata.get("securityClassification", "OFFICIAL")
            ],
            tags=metadata.get("tags", []),
        )

        return new_metadata


# jscpd:ignore-start
@dataclass
class DatabaseMetadata:
    """
    For source system databases - currently matches DataProductMetadata
    but will need to be revisted and refined potentially
    """

    name: str
    description: str
    version: str
    owner: str
    owner_display_name: str
    maintainer: str | None
    maintainer_display_name: str | None
    email: str
    retention_period_in_days: int
    domain: str
    subdomain: str | None
    dpia_required: bool
    dpia_location: str | None
    last_updated: datetime
    creation_date: datetime
    s3_location: str | None
    status: DataProductStatus = DataProductStatus.DRAFT
    tags: list[str] = field(default_factory=list)


# jscpd:ignore-end


@dataclass
class ChartMetadata:
    name: str
    description: str
    external_url: str
    tags: list[str] = field(default_factory=list)
