from dataclasses import dataclass, field
from typing import Any


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

    @staticmethod
    def from_data_product_metadata_dict(metadata: dict, version, owner_id: str):
        """
        Expects a dict containing data product metatdata information as per the
        required fields in the json schema at
        https://github.com/ministryofjustice/modernisation-platform-environments/tree/main/terraform/environments/data-platform/data-product-metadata-json-schema

        and should be pass version and owner id as in openmetadata.

        Then populates a DataProductMetadata object with the given data.
        """
        new_metadata = DataProductMetadata(
            name=metadata["name"],
            description=metadata["description"],
            version=version,
            owner=owner_id,
            email=metadata["email"],
            retention_period_in_days=metadata["retentionPeriod"],
            domain=metadata["domain"],
            dpia_required=metadata["dpiaRequired"],
            tags=metadata.get("tags", []),
        )

        return new_metadata


@dataclass
class TableMetadata:
    name: str
    description: str
    column_details: list
    retention_period_in_days: int | None
    tags: list[str] = field(default_factory=list)

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
            tags=metadata.get("tags", []),
        )

        return new_metadata
