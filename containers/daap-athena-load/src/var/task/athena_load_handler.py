import copy
import os
import re
import time
from typing import Tuple

import boto3
import s3fs
from botocore.exceptions import ClientError
from data_platform_logging import DataPlatformLogger
from mojap_metadata.converters.arrow_converter import ArrowConverter
from mojap_metadata.converters.glue_converter import GlueConverter
from pyarrow import csv as pa_csv
from pyarrow import parquet as pq

glue_client = boto3.client("glue")
athena_client = boto3.client("athena")
s3_client = boto3.client("s3")
s3_resource = boto3.resource("s3")

logger = DataPlatformLogger(extra={
    "image_version": os.getenv("VERSION", "unknown"),
    "base_image_version": os.getenv("BASE_VERSION", "unknown"),
})

s3_security_opts = {
    "ACL": 'bucket-owner-full-control',
    "ServerSideEncryption": 'AES256'
}


def start_query_execution_and_wait(
    database_name: str, data_bucket: str, sql: str
) -> str:
    """
    runs query for given sql and waits for completion
    """
    try:
        res = athena_client.start_query_execution(
            QueryString=sql,
            QueryExecutionContext={"Database": database_name},
            WorkGroup="data_product_workgroup",
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidRequestException':
            logger.error(f"This sql caused an error: {sql}")
            logger.write_log_dict_to_s3_json(bucket=data_bucket, **s3_security_opts)
            raise ValueError(e)
        else:
            logger.error(f"unexpected error: {e}")
            logger.write_log_dict_to_s3_json(bucket=data_bucket, **s3_security_opts)
            raise ValueError(e)

    query_id = res["QueryExecutionId"]
    while response := athena_client.get_query_execution(QueryExecutionId=query_id):
        state = response["QueryExecution"]["Status"]["State"]
        if state not in ["SUCCEEDED", "FAILED"]:
            time.sleep(0.1)
        else:
            break

    if not state == "SUCCEEDED":
        logger.error(
            "Query_id {}, failed with response: {}".format(
                query_id, response["QueryExecution"]["Status"].get("StateChangeReason")
            )
        )
        logger.write_log_dict_to_s3_json(bucket=data_bucket, **s3_security_opts)
        raise ValueError(response["QueryExecution"]["Status"].get("StateChangeReason"))

    return query_id


def get_data_product_config(key: str) -> dict:
    """
    takes the raw file key and populates a config dict
    for the product
    """

    config = {}
    config["bucket"], config["key"] = key.replace("s3://", "").split("/", 1)

    config["database_name"] = key.split("/")[4]
    config["table_name"] = key.split("/")[5]
    config["table_path_raw"] = os.path.dirname(key)

    config["table_path_curated"] = (
        os.path.join(
            "s3://",
            config["bucket"],
            "curated_data",
            "database_name={}".format(config["database_name"]),
            "table_name={}".format(config["table_name"]),
        )
        + "/"
    )

    # get timestamp value
    pattern = "^(.*)\/(extraction_timestamp=)([0-9TZ]{1,16})\/(.*)$"  # noqa W605
    m = re.match(pattern, key)
    if m:
        timestamp = m.group(3)
    else:
        raise ValueError(
            "Table partition extraction_timestamp is not in the expected format"
        )
    config["extraction_timestamp"] = timestamp
    config["account_id"] = boto3.client("sts").get_caller_identity()["Account"]

    return config


def _get_column_names_and_types(metadata) -> str:
    select_list = []
    for column in metadata["TableInput"]["StorageDescriptor"]["Columns"]:
        col_name = '"' + column["Name"] + '"'
        col_type = column["Type"] if not column["Type"] == "string" else "VARCHAR"
        col_no_zero_len_str = f"NULLIF({col_name},'')"
        select_list.append(f"CAST({col_no_zero_len_str} as {col_type}) as {col_name}")

    select_str = ",".join(select_list)

    return select_str


def sql_unload_table_partition(timestamp: str, table_name: str, table_path: str, metadata: dict) -> str:
    """
    generates sql string to unload a timestamped partition
    of raw data to given s3 location
    """
    partition_sql = f"""
        UNLOAD (
            SELECT
                {_get_column_names_and_types(metadata)},
                '{timestamp}' as extraction_timestamp
            FROM data_products_raw.{table_name}_raw
        )
        TO '{table_path}'
        WITH(
            format='parquet',
            compression = 'SNAPPY',
            partitioned_by=ARRAY['extraction_timestamp']
        )
    """

    return partition_sql


def sql_create_table_partition(
    database_name: str, table_name: str, table_path: str, timestamp: str, metadata: dict
) -> str:
    """
    if the table and data do not exist in curated this
    will create initial table and parition in glue and file
    in s3
    """
    partition_sql = f"""
        CREATE TABLE {database_name}.{table_name}
        WITH(
            format='parquet',
            write_compression = 'SNAPPY',
            external_location='{table_path}',
            partitioned_by=ARRAY['extraction_timestamp']
        ) AS
        SELECT
            {_get_column_names_and_types(metadata)},
            '{timestamp}' as extraction_timestamp
        FROM data_products_raw.{table_name}_raw
    """

    return partition_sql


def refresh_table_partitions(
    database_name: str, table_name: str
) -> None:
    """
    refreshes partitions following an update to a table
    """
    athena_client.start_query_execution(
        QueryString=f"MSCK REPAIR TABLE {database_name}.{table_name}",
        WorkGroup="data_product_workgroup",
    )


def does_partition_file_exist(
    bucket: str, db_name: str, table_name: str, timestamp: str
) -> bool:
    """
    returns bool indicating whether the extraction timestamp for
    a data product already exists
    """

    db_path = f"database_name={db_name}"
    table_path = f"table_name={table_name}/"
    paginator = s3_client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(
        Bucket=bucket, Prefix=os.path.join("curated_data", db_path, table_path)
    )
    response = []
    try:
        for page in page_iterator:
            response += page["Contents"]
    except KeyError as e:
        logger.error(
            f"No {e} key found at data product curated path – the database"
            " doesn't exist and will be created"
        )

    ts_exists = any(f"extraction_timestamp={timestamp}" in i["Key"] for i in response)
    logger.info(f"extraction_timestamp={timestamp} exists = {ts_exists}")

    return ts_exists


def infer_glue_schema(
    file_key: str,
    database_name: str,
    file_type: str = "csv",
    has_headers: bool = True,
    sample_size_mb: float = 1.5,
    table_type: str = "raw",
) -> Tuple[dict, dict]:
    """
    function infers and returns glue schema for csv and parquet files.
    schema are inferred using arrow
    """

    bucket, key = file_key.replace("s3://", "").split("/", 1)
    table_name = key.split("/")[2].replace("table_name=", "")

    raw_table_name = f"{table_name}_raw"

    if file_type == "csv":
        # can infer schema on a sample of data, here we stream a csv as a bytes object from s3
        # at the max size and then iterate over small chunk sizes to find a full line after
        # the max sample size, which we can then read into pyarrow and infer schema.
        max_size = int(sample_size_mb*1000000)
        start_byte = b''
        chunk_size = 5
        final_size = 0
        # the character that we'll split the data with (bytes, not string)
        # could csv dialect (newline character etc) from csv.sniffer in further dev
        newline = '\n'.encode()
        obj = boto3.resource("s3").Object(bucket, key)
        bytes_stream = obj.get()["Body"]
        finished = False

        while not finished:
            if final_size == 0:
                chunk = start_byte + bytes_stream.read(max_size)
            else:
                chunk = start_byte + bytes_stream.read(chunk_size)

            if chunk == b'':
                break

            last_newline = chunk.rfind(newline)

            if last_newline == 4:
                final_size += chunk_size
                if final_size > max_size:
                    finished = True
            else:
                if final_size == 0:
                    final_size += max_size
                else:
                    final_size += chunk_size
        bytes_stream_final = obj.get(Range=f'bytes=0-{final_size-1}')["Body"]
        logger.info(f"schema inferred using {round((final_size-1)/1000000,2)}MB sample")

        # null_values has been set to an empty list as "N/A" was being read as null (in a numeric column), with
        # type inferred as int but "N/A" persiting in the csv and so failing to be cast as an int.
        # Empty list means nothing inferred as null other than null.
        arrow_table = pa_csv.read_csv(
            bytes_stream_final,
            convert_options=pa_csv.ConvertOptions(null_values=[])
        )
    elif file_type == "parquet" and table_type == "curated":
        curated_prefix = file_key.replace("s3://" + bucket + "/", "")
        key = s3_client.list_objects_v2(Bucket=bucket, Prefix=curated_prefix)[
            "Contents"
        ][0]["Key"]

        s3 = s3fs.S3FileSystem()

        file_path = os.path.join("s3://", bucket, key)
        arrow_table = pq.ParquetDataset(
            file_path, filesystem=s3, use_legacy_dataset=False
        )

    arrow_schema = arrow_table.schema

    ac = ArrowConverter()
    gc = GlueConverter()
    metadata_mojap = ac.generate_to_meta(arrow_schema=arrow_schema)
    metadata_mojap.name = raw_table_name
    metadata_mojap.file_format = file_type
    metadata_mojap.column_names_to_lower(inplace=True)

    for col in metadata_mojap.columns:
        if col["type"] == "null":
            col["type"] = "string"
        # no spaces or brackets in column name
        col["name"] = col["name"].replace(" ", "_").replace("(", "").replace(")", "")

    if table_type == "curated":
        metadata_mojap.name = table_name
        metadata_mojap.columns.append(
            {"name": "extraction_timestamp", "type": "string"}
        )
        metadata_mojap.partitions = ["extraction_timestamp"]

    metadata_glue = gc.generate_from_meta(
        metadata_mojap,
        database_name=database_name,
        table_location=os.path.dirname(file_key),
    )

    if file_type == "csv" and has_headers:
        metadata_glue["TableInput"]["Parameters"]["skip.header.line.count"] = "1"
        metadata_glue["TableInput"]["StorageDescriptor"]["SerdeInfo"][
            "SerializationLibrary"
        ] = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

    # want a schema version where all columns are string type
    metadata_glue_str = copy.deepcopy(metadata_glue)

    for i, column in enumerate(metadata_glue_str["TableInput"]["StorageDescriptor"]["Columns"]):
        metadata_glue_str["TableInput"]["StorageDescriptor"]["Columns"][i]["Type"] = "string"

    return metadata_glue, metadata_glue_str


def create_raw_athena_table(metadata_glue: dict) -> None:
    """
    creates an athena table from the raw file pushed by
    a data producer
    """
    try:
        glue_client.get_database(Name="data_products_raw")
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            db_meta = {
                "DatabaseInput": {
                    "Description": "for holding tables of raw data products",
                    "Name": "data_products_raw",
                }
            }
            glue_client.create_database(**db_meta)
        else:
            logger.error("Unexpected error: %s" % e)
            raise
    table_name = metadata_glue["TableInput"]["Name"]
    try:
        glue_client.delete_table(DatabaseName="data_products_raw", Name=table_name)
    except ClientError:
        pass

    glue_client.create_table(**metadata_glue)
    logger.info(f"created table data_products_raw.{table_name}")


def create_curated_athena_table(
    database_name: str,
    table_name: str,
    curated_path: str,
    bucket: str,
    extraction_timestamp: str,
    metadata
):
    """
    creates curated parquet file from raw file and updates table
    to include latest timestamp partition from raw file uploaded
    """

    table_exists = False
    try:
        glue_client.get_database(Name=database_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            db_meta = {
                "DatabaseInput": {
                    "Description": "database for {} products".format(database_name),
                    "Name": database_name,
                }
            }
            glue_client.create_database(**db_meta)
        else:
            logger.error("Unexpected error: %s" % e)
            logger.write_log_dict_to_s3_json(bucket=bucket, **s3_security_opts)
            raise

    try:
        table_metadata = glue_client.get_table(
            DatabaseName=database_name, Name=table_name
        )
        if "table_metadata" in locals():
            table_exists = True

    except ClientError as e:
        curated_prefix = curated_path.replace("s3://" + bucket + "/", "")
        existing_files = s3_client.list_objects_v2(
            Bucket=bucket, Prefix=curated_prefix
        )["KeyCount"]
        if (
            e.response["Error"]["Code"] == "EntityNotFoundException"
            and existing_files == 0
        ):
            # only want to run this query if no table or data exist in s3
            qid = start_query_execution_and_wait(
                database_name,
                bucket,
                sql_create_table_partition(
                    database_name, table_name, curated_path, extraction_timestamp, metadata
                ),
            )
            logger.info(
                f"This is a new data product. Created {database_name}.{table_name}, using query id {qid}"
            )

            return

    partition_file_exists = does_partition_file_exist(
        bucket, database_name, table_name, extraction_timestamp
    )

    if table_exists and not partition_file_exists:
        logger.info("table does already exist but partition for timestamp does not")
        # unload query to make partitioned data
        qid = start_query_execution_and_wait(
            "data_products_raw",
            bucket,
            sql_unload_table_partition(extraction_timestamp, table_name, curated_path, metadata),
        )

        logger.info("Updated table {0}.{1}, using query id {2}".format(database_name, table_name, qid))
        refresh_table_partitions(database_name, table_name)

    elif not table_exists and partition_file_exists:
        logger.info("partition data exists but glue table does not")
        table_metadata, _ = infer_glue_schema(
            curated_path,
            database_name=database_name,
            file_type="parquet",
            table_type="curated",
        )

        glue_client.create_table(**table_metadata)
        refresh_table_partitions(database_name, table_name)
    elif not table_exists and not partition_file_exists:
        logger.info("table and partition do not exist but other curated data do")
        # unload query to make partitioned data
        qid = start_query_execution_and_wait(
            "data_products_raw",
            bucket,
            sql_unload_table_partition(extraction_timestamp, table_name, curated_path, metadata),
        )
        logger.info(f"created files for partition using query id {qid}")
        table_metadata, _ = infer_glue_schema(
            curated_path,
            database_name=database_name,
            file_type="parquet",
            table_type="curated",
        )
        glue_client.create_table(**table_metadata)
        refresh_table_partitions(database_name, table_name)

    else:
        logger.info(
            "partition for extraction_timestamp and table already exists so nothing more to be done."
        )


def clean_up_temp_tables(table_name: str) -> None:
    glue_client.delete_table(DatabaseName="data_products_raw", Name=table_name)
    logger.info(f"removed raw table data_products_raw.{table_name}")


def handler(event, context):
    bucket_name = event["detail"]["bucket"]["name"]
    file_key = event["detail"]["object"]["key"]

    full_s3_path = os.path.join("s3://", bucket_name, file_key)
    config = get_data_product_config(full_s3_path)

    logger.add_extras({
        "lambda_name": context.function_name,
        "data_product_name": config["database_name"],
        "table_name": config["table_name"]
    })

    logger.info(f"config: {config}")

    logger.info(f"file is: {full_s3_path}")
    metadata_types, metadata_str = infer_glue_schema(full_s3_path, "data_products_raw")

    create_raw_athena_table(metadata_str)
    create_curated_athena_table(
        config["database_name"],
        config["table_name"],
        config["table_path_curated"],
        config["bucket"],
        config["extraction_timestamp"],
        metadata_types
    )
    clean_up_temp_tables(config["table_name"] + "_raw")

    logger.write_log_dict_to_s3_json(bucket_name, **s3_security_opts)
