from datetime import datetime, timezone

from data_platform_catalogue.client.datahub.graphql_helpers import (
    parse_columns,
    parse_created_and_modified,
    parse_relations,
)
from data_platform_catalogue.entities import RelatedEntity, RelationshipType


def test_parse_columns_with_primary_key_and_foreign_key():
    entity = {
        "schemaMetadata": {
            "fields": [
                {
                    "fieldPath": "urn",
                    "label": None,
                    "nullable": False,
                    "description": "The primary identifier for the dataset entity.",
                    "type": "STRING",
                    "nativeDataType": "string",
                },
                {
                    "fieldPath": "[version=2.0].[type=dataset].[type=UpstreamLineage].upstreamLineage",
                    "label": None,
                    "nullable": False,
                    "description": "Upstream lineage of a dataset",
                    "type": "STRUCT",
                    "nativeDataType": "upstreamLineage",
                },
            ],
            "primaryKeys": ["urn"],
            "foreignKeys": [
                {
                    "name": "DownstreamOf",
                    "foreignFields": [{"fieldPath": "urn"}],
                    "foreignDataset": {
                        "urn": "urn:li:dataset:(urn:li:dataPlatform:datahub,Dataset,PROD)",
                        "properties": {"name": "Dataset", "qualifiedName": None},
                    },
                    "sourceFields": [
                        {
                            "fieldPath": "[version=2.0].[type=dataset].[type=UpstreamLineage].upstreamLineage"
                        }
                    ],
                }
            ],
        }
    }

    assert parse_columns(entity) == [
        {
            "name": "urn",
            "type": "string",
            "isPrimaryKey": True,
            "foreignKeys": [],
            "nullable": False,
            "description": "The primary identifier for the dataset entity.",
        },
        {
            "name": "[version=2.0].[type=dataset].[type=UpstreamLineage].upstreamLineage",
            "type": "upstreamLineage",
            "description": "Upstream lineage of a dataset",
            "nullable": False,
            "isPrimaryKey": False,
            "foreignKeys": [
                {
                    "tableId": "urn:li:dataset:(urn:li:dataPlatform:datahub,Dataset,PROD)",
                    "fieldName": "urn",
                    "tableName": "Dataset",
                }
            ],
        },
    ]


def test_parse_columns_with_no_keys():
    entity = {
        "schemaMetadata": {
            "fields": [
                {
                    "fieldPath": "urn",
                    "label": None,
                    "nullable": False,
                    "description": "The primary identifier for the dataset entity.",
                    "type": "STRING",
                    "nativeDataType": "string",
                },
                {
                    "fieldPath": "[version=2.0].[type=dataset].[type=UpstreamLineage].upstreamLineage",
                    "label": None,
                    "nullable": False,
                    "description": "Upstream lineage of a dataset",
                    "type": "STRUCT",
                    "nativeDataType": "upstreamLineage",
                },
            ],
            "primaryKeys": [],
            "foreignKeys": [],
        }
    }

    assert parse_columns(entity) == [
        {
            "name": "[version=2.0].[type=dataset].[type=UpstreamLineage].upstreamLineage",
            "type": "upstreamLineage",
            "description": "Upstream lineage of a dataset",
            "nullable": False,
            "isPrimaryKey": False,
            "foreignKeys": [],
        },
        {
            "name": "urn",
            "type": "string",
            "isPrimaryKey": False,
            "foreignKeys": [],
            "nullable": False,
            "description": "The primary identifier for the dataset entity.",
        },
    ]


def test_parse_columns_with_no_schema():
    entity = {}

    assert parse_columns(entity) == []
    assert parse_columns(entity) == []


def test_parse_relations():
    relations = {
        "relationships": {
            "total": 1,
            "relationships": [
                {
                    "entity": {
                        "urn": "urn:li:dataProduct:test",
                        "properties": {"name": "test"},
                    }
                }
            ],
        }
    }
    result = parse_relations(RelationshipType.PARENT, relations["relationships"])
    assert result == {
        RelationshipType.PARENT: [
            RelatedEntity(id="urn:li:dataProduct:test", name="test")
        ]
    }


def test_parse_relations_blank():
    relations = {"relationships": {"total": 0, "relationships": []}}
    result = parse_relations(RelationshipType.PARENT, relations["relationships"])
    assert result == {RelationshipType.PARENT: []}


def test_parse_created_and_modified():
    properties = {
        "created": 1710426920000,
        "lastModified": {"time": 1710426921000, "actor": "Shakira"},
    }

    created, modified = parse_created_and_modified(properties)

    assert created == datetime(2024, 3, 14, 14, 35, 20, tzinfo=timezone.utc)
    assert modified == datetime(2024, 3, 14, 14, 35, 21, tzinfo=timezone.utc)
