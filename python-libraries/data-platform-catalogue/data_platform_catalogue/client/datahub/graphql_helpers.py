from collections import defaultdict
from datetime import datetime, timezone
from typing import Any, Tuple

from data_platform_catalogue.entities import RelatedEntity, RelationshipType


def parse_owner(entity: dict[str, Any]):
    """
    Parse ownership information, if it is set.
    """
    ownership = entity.get("ownership") or {}
    owners = [i["owner"] for i in ownership.get("owners", [])]
    if owners:
        properties = owners[0].get("properties") or {}
        owner_email = properties.get("email", "")
        owner_name = properties.get("fullName", properties.get("displayName", ""))
    else:
        owner_email = ""
        owner_name = ""

    return owner_email, owner_name


def parse_last_updated(entity: dict[str, Any]) -> datetime | None:
    """
    Parse the last updated timestamp, if available
    """
    timestamp = entity.get("lastIngested")
    if timestamp is None:
        return None
    return datetime.fromtimestamp(timestamp / 1000, timezone.utc)


def parse_created_and_modified(
    properties: dict[str, Any]
) -> Tuple[datetime | None, datetime | None]:
    created = properties.get("created")
    modified = properties.get("lastModified")

    if created is not None:
        created = datetime.fromtimestamp(created / 1000, timezone.utc)
    if modified is not None:
        modified = datetime.fromtimestamp(modified / 1000, timezone.utc)

    return created, modified


def parse_tags(entity: dict[str, Any]) -> list[str]:
    """
    Parse tag information into a flat list of strings for displaying
    as part of the search result.
    """
    outer_tags = entity.get("tags") or {}
    tags = []
    for tag in outer_tags.get("tags", []):
        properties = tag["tag"]["properties"]
        if properties:
            tags.append(properties["name"])
    return tags


def parse_properties(entity: dict[str, Any]) -> Tuple[dict[str, Any], dict[str, Any]]:
    """
    Parse properties and editableProperties into a single dictionary.
    """
    properties = entity["properties"] or {}
    editable_properties = entity.get("editableProperties") or {}
    properties.update(editable_properties)
    custom_properties = {
        i["key"]: i["value"] for i in properties.get("customProperties", [])
    }
    return properties, custom_properties


def parse_domain(entity: dict[str, Any]):
    metadata = {}
    domain = entity.get("domain") or {}
    inner_domain = domain.get("domain") or {}
    metadata["domain_id"] = inner_domain.get("urn", "")
    if inner_domain:
        domain_properties, _ = parse_properties(inner_domain)
        metadata["domain_name"] = domain_properties.get("name", "")
    else:
        metadata["domain_name"] = ""
    return metadata


def parse_columns(entity: dict[str, Any]) -> list[dict[str, Any]]:
    """
    Parse the schema metadata from Datahub into a flattened list of column
    information.

    Note: The format of each column is similar to but not the same
    as the format used when ingesting table metadata.
    - `type` refers to the Datahub type, not AWS glue type
    - `nullable`, 'isPrimaryKey` and `foreignKeys` metadata is added
    """
    result = []

    schema_metadata = entity.get("schemaMetadata", {})
    if not schema_metadata:
        return []

    primary_keys = set(schema_metadata.get("primaryKeys") or ())

    foreign_keys = defaultdict(list)

    # Attempt to match foreign keys to the main fields.
    #
    # Assumptions:
    # - A given field may have multiple foreign keys to other datasets
    # - Some foreign keys will not match on fieldPath, because fields
    #   may be defined using STRUCT types and foreign keys can reference
    #   subfields within the struct. We will simply ignore these.
    for foreign_key in schema_metadata.get("foreignKeys") or ():
        if not foreign_key["sourceFields"] or not foreign_key["foreignFields"]:
            continue

        source_path = foreign_key["sourceFields"][0]["fieldPath"]
        foreign_path = foreign_key["foreignFields"][0]["fieldPath"]
        foreign_table_id = foreign_key["foreignDataset"]["urn"]
        foreign_table_name = foreign_key["foreignDataset"]["properties"]["name"]
        foreign_keys[source_path].append(
            {
                "tableId": foreign_table_id,
                "fieldName": foreign_path,
                "tableName": foreign_table_name,
            }
        )

    for field in schema_metadata.get("fields", ()):
        foreign_keys_for_field = foreign_keys[field["fieldPath"]]

        # Work out if the field is primary.
        # This is an oversimplification: in the case of a composite
        # primary key, we report that each component field is primary.
        is_primary_key = field["fieldPath"] in primary_keys

        result.append(
            {
                "name": field["fieldPath"],
                "description": field["description"],
                "type": field.get("nativeDataType", field["type"]),
                "nullable": field["nullable"],
                "isPrimaryKey": is_primary_key,
                "foreignKeys": foreign_keys_for_field,
            }
        )

    # Sort primary keys first, then sort alphabetically
    return sorted(result, key=lambda c: (0 if c["isPrimaryKey"] else 1, c["name"]))


def parse_relations(
    relationship_type: RelationshipType, relations_dict: dict
) -> dict[RelationshipType, list[RelatedEntity]]:
    """
    parse the relationships results returned from a graphql querys
    """
    # # we may want to do soemthing with total realtion if we are returning child relations
    # #  and need to paginate through relations - 10 relations returned as is
    # total_relations = relations_dict.get("total", 0)
    parent_entities = relations_dict.get("relationships", [])
    related_entities = [
        RelatedEntity(id=i["entity"]["urn"], name=i["entity"]["properties"]["name"])
        for i in parent_entities
    ]

    relations_return = {relationship_type: related_entities}
    return relations_return
