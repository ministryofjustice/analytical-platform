import os
from datetime import datetime
from io import BytesIO
from textwrap import dedent
from uuid import uuid4

import pytest
from data_platform_paths import BucketPath
from infer_glue_schema import (
    InferredMetadata,
    csv_sample,
    infer_glue_schema_from_raw_csv,
)


@pytest.mark.parametrize(
    "test_input,sample_size_in_bytes,expected",
    [
        (
            b"a,b,c",
            10,
            b"a,b,c",
        ),  # Should read to the end of the stream without encountering the line separator
        (
            b"a,b,c\nd,e,f",
            1,
            b"a,b,c\n",
        ),  # The sample size is the absolute minimum; should stop when hitting the line separator
        (
            b"a,b,c\nd,e,f\n",
            6,
            b"a,b,c\n",
        ),  # The sample size aligns with a line break. The following line shouldn't be read.
        (
            b"a,b,c\ndddddddddddd,eeeeeeeeeee,fffffffff",
            4,
            b"a,b,c\n",
        ),  # The sample size doesn't align with a line break. Stop when hitting the following line separator.
    ],
)
def test_csv_sample(test_input, expected, sample_size_in_bytes, logger):
    bytes_stream = BytesIO(test_input)
    output = csv_sample(
        bytes_stream, logger=logger, sample_size_in_bytes=sample_size_in_bytes
    ).getvalue()

    assert output == expected


def test_infer_schema_from_csv(s3_client, region_name, logger, data_product_element):
    # s3_client.create_bucket(Bucket=os.environ["BUCKET_NAME"])
    s3_client.create_bucket(
        Bucket=os.environ["BUCKET_NAME"],
        CreateBucketConfiguration={"LocationConstraint": region_name},
    )
    uuid_value = uuid4()
    path = data_product_element.raw_data_path(datetime(2023, 1, 1), uuid_value)

    s3_client.put_object(
        Key=path.key,
        Body=dedent(
            """
            some_string,some_number,some_mix,some_bool,some_float
            foo,123,1,true,1.2
            bar,456,N/A,,1.4
            ,456,N/A,,1.4
            """
        ),
        Bucket=os.environ["BUCKET_NAME"],
    )

    inferred_metadata = infer_glue_schema_from_raw_csv(
        file_path=BucketPath(path.bucket, path.key),
        data_product_element=data_product_element,
        logger=logger,
    )

    assert inferred_metadata.metadata["TableInput"]["StorageDescriptor"]["Columns"] == [
        {"Name": "some_string", "Type": "string"},
        {"Name": "some_number", "Type": "bigint"},
        {"Name": "some_mix", "Type": "string"},
        {"Name": "some_bool", "Type": "boolean"},
        {"Name": "some_float", "Type": "double"},
    ]

    assert inferred_metadata.metadata_str["TableInput"]["StorageDescriptor"][
        "Columns"
    ] == [
        {"Name": "some_string", "Type": "string"},
        {"Name": "some_number", "Type": "string"},
        {"Name": "some_mix", "Type": "string"},
        {"Name": "some_bool", "Type": "string"},
        {"Name": "some_float", "Type": "string"},
    ]


def test_inferred_metadata(raw_data_table, raw_table_metadata):
    result = InferredMetadata(raw_table_metadata)

    assert result.database_name == raw_data_table.database
    assert result.table_name == raw_data_table.name
    assert result.metadata == raw_table_metadata


def test_copy_inferred_metadata(raw_table_metadata):
    original = InferredMetadata(raw_table_metadata)
    result = original.copy(database_name="abc", table_name="def")

    assert result.database_name == "abc"
    assert result.table_name == "def"
    assert result.metadata != original.metadata
    assert (
        result.metadata["TableInput"]["StorageDescriptor"]["Columns"]
        == original.metadata["TableInput"]["StorageDescriptor"]["Columns"]
    )
