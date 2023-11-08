from unittest.mock import MagicMock

import athena_load_handler
import pytest
from data_platform_paths import get_metadata_bucket
from infer_glue_schema import InferredMetadata
from moto import mock_sts


@pytest.fixture
def fake_event():
    bucket_name = "bucket"
    key = "raw/data_product/table/load_timestamp=20230101T000000Z/file.csv"

    return {"detail": {"bucket": {"name": bucket_name}, "object": {"key": key}}}


@pytest.fixture()
def load_handler_prerequisites(mocker, s3_client):
    s3_client.create_bucket(Bucket=get_metadata_bucket())
    mocker.patch("data_platform_paths.s3", s3_client)

    # Patch all the helper methods to do nothing
    mocker.patch(
        "athena_load_handler.create_curated_athena_table",
        autospec=True,
    )
    mocker.patch("athena_load_handler.temporary_raw_athena_table", autospec=True)
    mock_infer_schema = mocker.patch(
        "athena_load_handler.infer_glue_schema_from_raw_csv", autospec=True
    )

    mock_infer_schema.return_value = InferredMetadata(
        {
            "DatabaseName": "data_products_raw",
            "TableInput": {"Name": "temp", "StorageDescriptor": {"Columns": []}},
        },
    )


@mock_sts
def test_handler_existing_schema_does_not_error(
    fake_context,
    fake_event,
    load_handler_prerequisites,
    s3_client,
    glue_client,
    athena_client,
):
    """
    Test the handler doesn't error when passed valid input
    """

    athena_load_handler.handler(
        fake_event,
        fake_context,
        s3_client=s3_client,
        glue_client=MagicMock(glue_client),
        athena_client=athena_client,
    )


@mock_sts
def test_handler_no_schema_found(
    fake_context,
    fake_event,
    mocker,
    load_handler_prerequisites,
    s3_client,
    glue_client,
    athena_client,
):
    """
    Test the handler doesn't error when passed valid input
    """
    mocker.patch.object(
        athena_load_handler.DataProductSchema,
        "latest_version_saved_data",
        side_effect=AttributeError(),
        create=True,
    )

    athena_load_handler.handler(
        fake_event,
        fake_context,
        s3_client=s3_client,
        glue_client=MagicMock(glue_client),
        athena_client=athena_client,
    )
