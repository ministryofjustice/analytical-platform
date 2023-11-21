import logging
from unittest.mock import patch

from glue_and_athena_utils import create_glue_database, delete_glue_table, table_exists


def test_create_glue_database(glue_client):
    database_name = "test_db"
    table_name = "test_table"
    create_glue_database(glue_client, database_name, logging.getLogger())
    response = glue_client.get_database(Name=database_name)
    assert response["Database"]["Name"] == database_name


def test_delete_glue_table(glue_client):
    database_name = "test_db"
    table_name = "test_table"
    create_glue_database(glue_client, database_name, logging.getLogger())

    glue_client.create_table(
        DatabaseName=database_name,
        TableInput={
            "Name": table_name,
            "StorageDescriptor": {
                "Columns": [
                    {
                        "Name": "col1",
                        "Type": "string",
                    },
                ],
            },
        },
    )
    with patch("glue_and_athena_utils.glue_client", glue_client):
        resp = delete_glue_table(database_name, table_name, logging.getLogger())

    assert resp["ResponseMetadata"]["HTTPStatusCode"] == 200


def test_table_exists(glue_client):
    database_name = "test_db"
    table_name = "test_table"
    create_glue_database(glue_client, database_name, logging.getLogger())

    glue_client.create_table(
        DatabaseName=database_name,
        TableInput={
            "Name": table_name,
            "StorageDescriptor": {
                "Columns": [
                    {
                        "Name": "col1",
                        "Type": "string",
                    },
                ],
            },
        },
    )

    with patch("glue_and_athena_utils.glue_client", glue_client):
        result = table_exists(database_name, table_name)
        assert result
