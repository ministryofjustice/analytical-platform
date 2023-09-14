from unittest.mock import create_autospec

import create_raw_athena_table
from data_platform_logging import DataPlatformLogger


def test_create_raw_athena_table(glue_client):
    logger = create_autospec(DataPlatformLogger)

    create_raw_athena_table.create_raw_athena_table(
        metadata_glue={
            "TableInput": {"Name": "table"},
            "DatabaseName": "data_products_raw",
        },
        logger=logger,
        glue_client=glue_client,
        bucket="bucket",
        s3_security_opts={},
    )

    table = glue_client.get_table(Name="table", DatabaseName="data_products_raw")
    assert table["Table"]["VersionId"] == "1"


def test_create_raw_athena_table_recreates_the_db(glue_client):
    logger = create_autospec(DataPlatformLogger)

    glue_client.create_database(DatabaseInput={"Name": "data_products_raw"})
    glue_client.create_table(
        TableInput={"Name": "table"}, DatabaseName="data_products_raw"
    )

    create_raw_athena_table.create_raw_athena_table(
        metadata_glue={
            "TableInput": {"Name": "table"},
            "DatabaseName": "data_products_raw",
        },
        logger=logger,
        glue_client=glue_client,
        bucket="bucket",
        s3_security_opts={},
    )

    table = glue_client.get_table(Name="table", DatabaseName="data_products_raw")
    assert table["Table"]["VersionId"] == "1"
