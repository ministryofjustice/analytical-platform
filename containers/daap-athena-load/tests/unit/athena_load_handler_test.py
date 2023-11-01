from unittest.mock import MagicMock

import athena_load_handler
from data_platform_paths import get_metadata_bucket
from infer_glue_schema import InferredMetadata
from moto import mock_sts


@mock_sts
def test_handler_does_not_error(
    fake_context, mocker, s3_client, glue_client, athena_client
):
    """
    Test the handler doesn't error when passed valid input
    """
    bucket_name = "bucket"
    key = "raw/data_product/table/load_timestamp=20230101T000000Z/file.csv"

    s3_client.create_bucket(Bucket=get_metadata_bucket())
    mocker.patch("data_platform_paths.s3_client", s3_client)

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

    athena_load_handler.handler(
        {"detail": {"bucket": {"name": bucket_name}, "object": {"key": key}}},
        fake_context,
        s3_client=s3_client,
        glue_client=MagicMock(glue_client),
        athena_client=athena_client,
    )
