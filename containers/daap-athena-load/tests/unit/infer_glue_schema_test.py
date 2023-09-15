from datetime import datetime
from textwrap import dedent
from uuid import uuid4

import pyarrow as pa
from data_platform_paths import BucketPath
from infer_glue_schema import infer_glue_schema
from pyarrow import parquet as pq


def test_infer_schema_from_csv(s3_client, logger, data_product):
    s3_client.create_bucket(Bucket="bucket")
    uuid_value = uuid4()
    path = data_product.raw_data_path(datetime(2023, 1, 1), uuid_value)

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
        data_product_config=data_product,
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


def test_infer_schema_from_parquet(s3_client, logger, data_product):
    table = pa.Table.from_arrays(
        [
            pa.array([2, 4, 5, 100]),
            pa.array(["Flamingo", "Horse", "Brittle stars", "Centipede"]),
        ],
        names=["n_legs", "animals"],
    )
    output = pa.BufferOutputStream()
    pq.write_table(table, output)

    path = data_product.curated_data_prefix.key + "foo.parquet"
    s3_client.create_bucket(Bucket="bucket")
    s3_client.put_object(
        Key=path,
        Body=output.getvalue().to_pybytes(),
        Bucket="bucket",
    )

    metadata_glue, metadata_glue_str = infer_glue_schema(
        file_path=data_product.curated_data_prefix,
        data_product_config=data_product,
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
