import logging
from unittest.mock import patch

import pytest
from glue_and_athena_utils import (
    clone_database,
    create_database,
    create_table,
    database_exists,
    delete_database,
    delete_table,
    get_database,
    get_table,
    list_tables,
    table_exists,
)

logger = logging.getLogger()


@pytest.fixture(autouse=True)
def patch_glue_client(glue_client):
    with patch("glue_and_athena_utils.glue_client", glue_client):
        yield


@pytest.fixture
def database_name():
    return "test_db"


@pytest.fixture
def description():
    return "test_description"


class TestDatabaseOperations:
    @pytest.fixture
    def database_name(self):
        return "test_db"

    @pytest.fixture
    def description(self):
        return "test_description"

    def test_create_and_get(self, database_name):
        create_database(database_name=database_name, logger=logger)
        response = get_database(database_name=database_name, logger=logger)

        assert response["Database"]["Name"] == database_name

    def test_create_with_db_meta(self, database_name, description):
        db_meta = {
            "DatabaseInput": {
                "Description": description,
                "Name": database_name,
            }
        }
        create_database(database_name=database_name, logger=logger, db_meta=db_meta)
        response = get_database(database_name=database_name, logger=logger)

        assert response["Database"]["Name"] == database_name
        assert response["Database"]["Description"] == description

    def test_database_exists(self, database_name):
        create_database(database_name=database_name, logger=logger)

        assert database_exists(database_name=database_name, logger=logger)

    def test_delete_existing_database(self, database_name):
        create_database(database_name=database_name, logger=logger)

        delete_database(database_name=database_name, logger=logger)

        assert not database_exists(database_name=database_name, logger=logger)

    def test_delete_missing_database(self, database_name):
        delete_database(database_name=database_name, logger=logger)

        assert not database_exists(database_name=database_name, logger=logger)

    def test_clone_database(self, database_name, description):
        db_meta = {
            "DatabaseInput": {
                "Description": description,
                "Name": database_name,
            }
        }
        create_database(
            database_name=database_name,
            logger=logger,
            db_meta=db_meta,
        )

        clone_database(
            existing_database_name=database_name,
            new_database_name="new",
            logger=logger,
        )
        result = get_database(database_name="new", logger=logger)

        assert result["Database"]["Name"] == "new"
        assert result["Database"]["Description"] == description

    def test_clone_database_with_tables(self, database_name):
        create_database(
            database_name=database_name,
            logger=logger,
        )
        create_table(database_name=database_name, table_name="foo", logger=logger)

        clone_database(
            existing_database_name=database_name,
            new_database_name="new",
            logger=logger,
        )
        result = list_tables(database_name=database_name, logger=logger)
        assert [i["Name"] for i in result["TableList"]] == ["foo"]


class TestTableOperations:
    @pytest.fixture
    def table_name(self):
        return "test_table"

    @pytest.fixture
    def table_meta(self, table_name):
        return {
            "TableInput": {
                "Name": table_name,
                "StorageDescriptor": {
                    "Columns": [
                        {
                            "Name": "col1",
                            "Type": "string",
                        },
                    ],
                },
            }
        }

    def test_create_and_get_table(self, database_name, table_name, table_meta):
        create_database(database_name, logging.getLogger())

        create_table(
            database_name=database_name,
            logger=logger,
            table_meta=table_meta,
        )

        result = get_table(
            database_name=database_name, table_name=table_name, logger=logger
        )
        assert result["Table"]["Name"] == table_name

    def test_list_tables(self, database_name, table_name):
        table_name_1 = table_name + "_1"
        table_name_2 = table_name + "_2"
        create_database(database_name, logging.getLogger())

        create_table(
            database_name=database_name, logger=logger, table_name=table_name_1
        )
        create_table(
            database_name=database_name, logger=logger, table_name=table_name_2
        )

        result = list_tables(database_name=database_name, logger=logger)
        assert [i["Name"] for i in result["TableList"]] == [table_name_1, table_name_2]

    def test_table_exists(self, database_name, table_name, table_meta):
        create_database(database_name, logging.getLogger())

        create_table(
            database_name=database_name,
            logger=logger,
            table_meta=table_meta,
        )

        result = table_exists(database_name, table_name)
        assert result

    def test_delete_table(
        self,
        database_name,
        table_name,
        table_meta,
    ):
        create_database(database_name, logging.getLogger())
        create_table(database_name=database_name, logger=logger, table_meta=table_meta)

        resp = delete_table(database_name, table_name, logging.getLogger())

        assert resp["ResponseMetadata"]["HTTPStatusCode"] == 200
