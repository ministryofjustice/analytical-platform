from data_platform_catalogue.client.datahub.graphql_helpers import parse_columns


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
            "type": "STRING",
            "isPrimaryKey": True,
            "foreignKeys": [],
            "nullable": False,
            "description": "The primary identifier for the dataset entity.",
        },
        {
            "name": "[version=2.0].[type=dataset].[type=UpstreamLineage].upstreamLineage",
            "type": "STRUCT",
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
            "type": "STRUCT",
            "description": "Upstream lineage of a dataset",
            "nullable": False,
            "isPrimaryKey": False,
            "foreignKeys": [],
        },
        {
            "name": "urn",
            "type": "STRING",
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
