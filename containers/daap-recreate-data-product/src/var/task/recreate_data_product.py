import os

import boto3


def handler(event, context):
    data_product_to_recreate = event.get("data_product", "")
    raw_data_bucket = os.environ.get("RAW_DATA_BUCKET", "")
    curated_data_bucket = os.environ.get("CURATED_DATA_BUCKET", "")
    athena_load_lambda = os.environ.get("ATHENA_LOAD_LAMBDA", "")

    # Check data product has associated data
    s3 = boto3.client("s3")
    s3_response = s3.list_objects_v2(
        Bucket=raw_data_bucket, Prefix=f"raw_data/{data_product_to_recreate}"
    )
    data_product_registration = s3_response.get("Contents", [])
    print(data_product_registration)
    if not any(data_product_registration):
        raise ValueError(f"No data product found for {data_product_to_recreate}")

    # Drop existing athena tables for that data product
    glue = boto3.client("glue")
    glue_response = glue.get_tables(DatabaseName=data_product_to_recreate)
    data_product_tables = glue_response.get("TableList", [])
    if not any(data_product_tables):
        print(f"No tables found for data product {data_product_to_recreate}")
    for table in data_product_tables:
        glue.delete_table(DatabaseName=data_product_to_recreate, Name=table["Name"])

    # Remove curated data files for that data product
    s3_recursive_delete(
        bucket=curated_data_bucket,
        prefix=f"curated_data/database_name={data_product_to_recreate}/",
        s3_client=s3,
    )

    # Feed all data files through the load process again. Curated files are recreated.
    # If there are over 1000 files, the lambda will get jammed up
    aws_lambda = boto3.client("lambda")
    for file in data_product_registration:
        key = file["Key"]
        payload = f'{{"detail":{{"bucket":{{"name":"{raw_data_bucket}"}}, "object":{{"key":"{key}"}}}}}}'
        aws_lambda.invoke(
            FunctionName=athena_load_lambda, InvocationType="Event", Payload=payload
        )

    print(f"data product {data_product_to_recreate} recreated")


def s3_recursive_delete(bucket, prefix, s3_client) -> None:
    """Delete all files from a prefix in s3"""
    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=prefix)

    delete_us = dict(Objects=[])
    for item in pages.search("Contents"):
        delete_us["Objects"].append(dict(Key=item["Key"]))

        # delete once aws limit reached
        if len(delete_us["Objects"]) >= 1000:
            s3_client.delete_objects(Bucket=bucket, Delete=delete_us)
            delete_us = dict(Objects=[])
            print(f"deleted 1000 data files from {prefix}")

    # delete remaining
    if len(delete_us["Objects"]):
        s3_client.delete_objects(Bucket=bucket, Delete=delete_us)
        print(f"deleted all data files from {prefix}/")
