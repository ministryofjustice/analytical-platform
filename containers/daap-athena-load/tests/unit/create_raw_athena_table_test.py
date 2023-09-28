import create_raw_athena_table
import pytest
from botocore.exceptions import ClientError
from infer_glue_schema import InferredMetadata


def test_create_raw_athena_table(glue_client, logger):
    create_raw_athena_table.create_raw_athena_table(
        metadata=InferredMetadata(
            {
                "TableInput": {
                    "Name": "table",
                    "StorageDescriptor": {"Columns": []},
                },
                "DatabaseName": "data_products_raw",
            }
        ),
        logger=logger,
        glue_client=glue_client,
    )

    table = glue_client.get_table(Name="table", DatabaseName="data_products_raw")
    assert table["Table"]["VersionId"] == "1"


def test_create_raw_athena_table_recreates_the_db(glue_client, logger):
    glue_client.create_database(DatabaseInput={"Name": "data_products_raw"})
    glue_client.create_table(
        TableInput={"Name": "table"}, DatabaseName="data_products_raw"
    )

    create_raw_athena_table.create_raw_athena_table(
        metadata=InferredMetadata(
            {
                "TableInput": {
                    "Name": "table",
                    "StorageDescriptor": {"Columns": []},
                },
                "DatabaseName": "data_products_raw",
            }
        ),
        logger=logger,
        glue_client=glue_client,
    )

    table = glue_client.get_table(Name="table", DatabaseName="data_products_raw")
    assert table["Table"]["VersionId"] == "1"


def test_context_manager_creates_and_deletes_table(glue_client, logger):
    with create_raw_athena_table.temporary_raw_athena_table(
        metadata=InferredMetadata(
            {
                "TableInput": {
                    "Name": "temporary",
                    "StorageDescriptor": {"Columns": []},
                },
                "DatabaseName": "data_products_raw",
            }
        ),
        logger=logger,
        glue_client=glue_client,
    ):
        table = glue_client.get_table(
            Name="temporary", DatabaseName="data_products_raw"
        )
        assert table["Table"]["VersionId"] == "1"

    with pytest.raises(ClientError):
        glue_client.get_table(Name="temporary", DatabaseName="data_products_raw")
