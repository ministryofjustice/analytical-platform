from datetime import datetime
from textwrap import dedent
from uuid import uuid4
from io import BytesIO

import pyarrow as pa
from data_platform_paths import BucketPath
from infer_glue_schema import infer_glue_schema, csv_sample
from pyarrow import parquet as pq
import pytest


@pytest.mark.parametrize(
    "test_input,sample_size_in_bytes,expected",
    [
        (b"a,b,c", 10, b"a,b,c"),
        (b"a,b,c\nd,e,f", 1, b"a,b,c\n"),
    ],
)
def test_csv_sample(test_input, expected, sample_size_in_bytes, logger):
    bytes_stream = BytesIO(test_input)
    output = csv_sample(
        bytes_stream, logger=logger, sample_size_in_bytes=sample_size_in_bytes
    ).getvalue()

    assert output == expected


def test_infer_schema_from_csv(s3_client, logger, data_product_element):
    s3_client.create_bucket(Bucket="bucket")
    uuid_value = uuid4()
    path = data_product_element.raw_data_path(datetime(2023, 1, 1), uuid_value)

    s3_client.put_object(
        Key=path.key,
        Body=dedent(
            """
            some_string,some_number
            foo,123
            bar,456
            """
        ),
        Bucket="bucket",
    )

    metadata_glue, metadata_glue_str = infer_glue_schema(
        file_path=BucketPath(path.bucket, path.key),
        data_product_element=data_product_element,
        logger=logger,
    )

    assert metadata_glue["TableInput"]["StorageDescriptor"]["Columns"] == [
        {"Name": "some_string", "Type": "string"},
        {"Name": "some_number", "Type": "bigint"},
    ]

    assert metadata_glue_str["TableInput"]["StorageDescriptor"]["Columns"] == [
        {"Name": "some_string", "Type": "string"},
        {"Name": "some_number", "Type": "string"},
    ]


def test_infer_schema_from_parquet(s3_client, logger, data_product_element):
    table = pa.Table.from_arrays(
        [
            pa.array([2, 4, 5, 100]),
            pa.array(["Flamingo", "Horse", "Brittle stars", "Centipede"]),
        ],
        names=["n_legs", "animals"],
    )
    output = pa.BufferOutputStream()
    pq.write_table(table, output)

    path = data_product_element.curated_data_prefix.key + "foo.parquet"
    s3_client.create_bucket(Bucket="bucket")
    s3_client.put_object(
        Key=path,
        Body=output.getvalue().to_pybytes(),
        Bucket="bucket",
    )

    metadata_glue, metadata_glue_str = infer_glue_schema(
        file_path=data_product_element.curated_data_prefix,
        data_product_element=data_product_element,
        logger=logger,
        table_type="curated",
        file_type="parquet",
    )

    assert metadata_glue["TableInput"]["StorageDescriptor"]["Columns"] == [
        {"Name": "n_legs", "Type": "bigint"},
        {"Name": "animals", "Type": "string"},
    ]

    assert metadata_glue_str["TableInput"]["StorageDescriptor"]["Columns"] == [
        {"Name": "n_legs", "Type": "string"},
        {"Name": "animals", "Type": "string"},
    ]
