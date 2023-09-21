from unittest.mock import MagicMock

import athena_load_handler
from moto import mock_sts


@mock_sts
def test_handler_does_not_error(
    fake_context, mocker, s3_client, glue_client, athena_client
):
    """
    Test the handler doesn't error when passed valid input
    """
    bucket_name = "bucket"
    key = "raw_data/data_product/table/extraction_timestamp=20230101T000000Z/file.csv"

    # Patch all the helper methods to do nothing
    mocker.patch(
        "athena_load_handler.create_curated_athena_table",
        autospec=True,
    )
    mocker.patch("athena_load_handler.create_raw_athena_table", autospec=True)
    mock_infer_schema = mocker.patch(
        "athena_load_handler.infer_glue_schema", autospec=True
    )

    mock_infer_schema.return_value = (
        {"DatabaseName": "data_products_raw", "TableInput": {"Name": "temp"}},
        {"DatabaseName": "data_products_raw", "TableInput": {"Name": "temp"}},
    )

    athena_load_handler.handler(
        {"detail": {"bucket": {"name": bucket_name}, "object": {"key": key}}},
        fake_context,
        s3_client=s3_client,
        glue_client=MagicMock(glue_client),
        athena_client=athena_client,
    )
