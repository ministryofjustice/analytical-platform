import os

import boto3


def handler(event, context):
    data_product_to_recreate = event.get("data_product", "")
    raw_prefix = f"raw_data/{data_product_to_recreate}"
    curated_prefix = f"curated_data/database_name={data_product_to_recreate}"
    raw_data_bucket = os.environ.get("RAW_DATA_BUCKET", "")
    curated_data_bucket = os.environ.get("CURATED_DATA_BUCKET", "")
    athena_load_lambda = os.environ.get("ATHENA_LOAD_LAMBDA", "")

    # Check data product has associated data
    s3 = boto3.client("s3")
    s3_response = s3.list_objects_v2(Bucket=raw_data_bucket, Prefix=raw_prefix)
    data_product_registration = s3_response.get("Contents", [])
    if not any(data_product_registration):
        raise ValueError(f"No data product found for {data_product_to_recreate}")
    print(data_product_registration)

    # Find extraction timestamps in the raw area, and not in the curated area
    paginator = s3.get_paginator("list_objects_v2")
    raw_pages = paginator.paginate(Bucket=raw_data_bucket, Prefix=raw_prefix)
    curated_pages = paginator.paginate(
        Bucket=curated_data_bucket, Prefix=curated_prefix
    )

    # key = "raw_data/data_product/table/extraction_timestamp=timestamp/file.csv"
    raw_table_timestamps = set(
        "/".join(item["Key"].split("/")[1:4])
        for item in raw_pages.search("Contents")
        if item["Size"] > 0
    )

    curated_table_timestamps = set()
    for item in curated_pages.search("Contents"):
        # key = "curated_data/database_name=data_product/table_name=table"
        #       + "/extraction_timestamp=timestamp/file.parquet"
        if item["Size"] > 0:
            key_parts = item["Key"].split("/")
            data_product = key_parts[1].split("=")[1]
            table = key_parts[2].split("=")[1]
            # Both sets need the same formatting to compare them
            curated_table_timestamps.add(f"{data_product}/{table}/{key_parts[3]}")

    timestamps_to_resync = raw_table_timestamps - curated_table_timestamps
    raw_keys_to_resync = [
        item["Key"]
        for timestamp in timestamps_to_resync
        for item in raw_pages.search("Contents")
        if timestamp in item["Key"]
    ]
    print("raw keys to resync:", raw_keys_to_resync)

    # Feed unprocessed data files through the load process again.
    # If there are over 1000 files, the lambda will get jammed up
    aws_lambda = boto3.client("lambda")
    for key in raw_keys_to_resync:
        payload = f'{{"detail":{{"bucket":{{"name":"{raw_data_bucket}"}}, "object":{{"key":"{key}"}}}}}}'
        aws_lambda.invoke(
            FunctionName=athena_load_lambda, InvocationType="Event", Payload=payload
        )

    print(
        f"data product {data_product_to_recreate} resynced with {len(raw_keys_to_resync)} files"
    )
    print(str(raw_keys_to_resync))
