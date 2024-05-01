from collections import defaultdict
from datetime import datetime, timezone
from typing import Any, Tuple

from data_platform_catalogue.entities import (
    AccessInformation,
    Column,
    ColumnRef,
    CustomEntityProperties,
    DataSummary,
    DomainRef,
    EntityRef,
    OwnerRef,
    RelationshipType,
    TagRef,
    UsageRestrictions,
)


def parse_owner(entity: dict[str, Any]) -> OwnerRef:
    """
    Parse ownership information, if it is set.
    If no owner information exists, return an OwnerRef populated with blank strings
    """
    ownership = entity.get("ownership") or {}
    owners = [i["owner"] for i in ownership.get("owners", [])]
    if owners:
        properties = owners[0].get("properties") or {}
        owner_details = OwnerRef(
            display_name=properties.get("displayName", properties.get("fullName", "")),
            email=properties.get("email", ""),
            urn=owners[0].get("urn", ""),
        )
    else:
        owner_details = OwnerRef(display_name="", email="", urn="")

    return owner_details


def parse_last_modified(entity: dict[str, Any]) -> datetime | None:
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
    modified = properties.get("lastModified", {}).get("time")

    if created is not None:
        created = datetime.fromtimestamp(created / 1000, timezone.utc)
    if modified is not None:
        modified = datetime.fromtimestamp(modified / 1000, timezone.utc)

    return created, modified


def parse_tags(entity: dict[str, Any]) -> list[TagRef]:
    """
    Parse tag information into a flat list of strings for displaying
    as part of the search result.
    """
    outer_tags = entity.get("tags") or {}
    tags = []
    for tag in outer_tags.get("tags", []):
        properties = tag.get("tag", {}).get("properties", {})
        if properties:
            tags.append(
                TagRef(
                    display_name=properties.get("name", ""),
                    urn=tag.get("tag", {}).get("urn", ""),
                )
            )
    return tags


def parse_properties(
    entity: dict[str, Any]
) -> Tuple[dict[str, Any], CustomEntityProperties]:
    """
    Parse properties and editableProperties into a single dictionary.
    """
    properties = entity["properties"] or {}
    editable_properties = entity.get("editableProperties") or {}
    properties.update(editable_properties)
    custom_properties_dict = {
        i["key"]: i["value"] or "" for i in properties.get("customProperties", [])
    }

    if "dpia_required" in custom_properties_dict:
        custom_properties_dict["dpia_required"] = (
            custom_properties_dict["dpia_required"] == "True"
        )

    properties.pop("customProperties", None)
    access_information = AccessInformation.model_validate(custom_properties_dict)
    usage_restrictions = UsageRestrictions.model_validate(custom_properties_dict)
    data_summary = DataSummary.model_validate(custom_properties_dict)

    custom_properties = CustomEntityProperties(
        access_information=access_information,
        usage_restrictions=usage_restrictions,
        data_summary=data_summary,
    )

    return properties, custom_properties


def parse_names(
    entity: dict[str, Any], properties: dict[str, Any]
) -> Tuple[str, str, str]:
    """
    Returns a tuple of 3 name values.

    The first value is the non-qualified version of the entity name,
    and the second value is the human-friendly display name.

    Either of these can be used when showing the entity providing it is within
    the context of its container.

    The third value is the fully qualified name (e.g. my_database.my_table), which
    can be used to show the entity out of context.
    """
    top_level_name = entity.get("name")
    name = properties.get("name", top_level_name)
    display_name = properties.get("displayName") or name
    qualified_name = properties.get("qualifiedName") or top_level_name or name

    return name, display_name, qualified_name


def parse_domain(entity: dict[str, Any]) -> DomainRef:
    domain = entity.get("domain") or {}
    inner_domain = domain.get("domain") or {}
    domain_id = inner_domain.get("urn", "")
    if inner_domain:
        domain_properties, _ = parse_properties(inner_domain)
        display_name = domain_properties.get("name", "")
    else:
        display_name = ""

    return DomainRef(display_name=display_name, urn=domain_id)


def parse_columns(entity: dict[str, Any]) -> list[Column]:
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

        foreign_table = EntityRef(
            urn=foreign_key["foreignDataset"]["urn"],
            display_name=foreign_key["foreignDataset"]["properties"]["name"],
        )

        display_name = foreign_path.split(".")[-1]
        foreign_keys[source_path].append(
            ColumnRef(name=foreign_path, display_name=display_name, table=foreign_table)
        )

    for field in schema_metadata.get("fields", ()):
        foreign_keys_for_field = foreign_keys[field["fieldPath"]]

        # Work out if the field is primary.
        # This is an oversimplification: in the case of a composite
        # primary key, we report that each component field is primary.
        is_primary_key = field["fieldPath"] in primary_keys
        field_path = field["fieldPath"]
        display_name = field_path.split(".")[-1]

        result.append(
            Column(
                name=field_path,
                display_name=display_name,
                description=field.get("description") or "",
                type=field.get("nativeDataType", field["type"]),
                nullable=field["nullable"],
                is_primary_key=is_primary_key,
                foreign_keys=foreign_keys_for_field,
            )
        )

    # Sort primary keys first, then sort alphabetically
    return sorted(result, key=lambda c: (0 if c.is_primary_key else 1, c.name))


def parse_relations(
    relationship_type: RelationshipType, relations_dict: dict
) -> dict[RelationshipType, list[EntityRef]]:
    """
    parse the relationships results returned from a graphql querys
    """
    # # we may want to do soemthing with total realtion if we are returning child relations
    # #  and need to paginate through relations - 10 relations returned as is
    # total_relations = relations_dict.get("total", 0)
    parent_entities = relations_dict.get("relationships", [])
    related_entities = [
        EntityRef(
            urn=i["entity"]["urn"], display_name=i["entity"]["properties"]["name"]
        )
        for i in parent_entities
    ]

    relations_return = {relationship_type: related_entities}
    return relations_return
