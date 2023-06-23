import ast
import logging
import os
import re
import time

import boto3
import pyarrow as pa
import s3fs
from botocore.exceptions import ClientError
from mojap_metadata.converters.arrow_converter import ArrowConverter
from mojap_metadata.converters.glue_converter import GlueConverter
from pyarrow import parquet as pq

logging.getLogger().setLevel(logging.INFO)

glue_client = boto3.client("glue")
athena_client = boto3.client("athena")
s3_client = boto3.client("s3")
s3_resource = boto3.resource("s3")


def start_query_execution_and_wait(
    database_name: str, account_id: str, sql: str
) -> None:
    """
    runs query for given sql and waits for completion
    """

    res = athena_client.start_query_execution(
        QueryString=sql,
        QueryExecutionContext={"Database": database_name},
        WorkGroup="data_product_workgroup",
    )
    query_id = res["QueryExecutionId"]
    while response := athena_client.get_query_execution(QueryExecutionId=query_id):
        state = response["QueryExecution"]["Status"]["State"]
        if state not in ["SUCCEEDED", "FAILED"]:
            time.sleep(0.1)
        else:
            break

    if not state == "SUCCEEDED":
        raise ValueError(response["QueryExecution"]["Status"].get("StateChangeReason"))


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


def _tryeval(val: str):
    """
    takes decoded byte values that are strings and
    evaluates their type

    """
    try:
        val = ast.literal_eval(val)
    except (ValueError, SyntaxError):
        pass
    return val


def sql_unload_table_partition(timestamp: str, table_name: str, table_path: str) -> str:
    """
    generates sql string to unload a timestamped partition
    of raw data to given s3 location
    """
    partition_sql = f"""
        UNLOAD (
            SELECT
                *,
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
    database_name: str, table_name: str, table_path: str, timestamp: str
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
            *,
            '{timestamp}' as extraction_timestamp
        FROM data_products_raw.{table_name}_raw
    """

    return partition_sql


def refresh_table_partitions(
    database_name: str, table_name: str, account_id: str
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
        logging.error(
            f"No {e} key found at data product curated path – the database"
            " doesn't exist and will be created"
        )

    ts_exists = any(f"extraction_timestamp={timestamp}" in i["Key"] for i in response)
    logging.info(f"extraction_timestamp={timestamp} exists = {ts_exists}")

    return ts_exists


def infer_glue_schema(
    file_key: str,
    database_name: str,
    file_type: str = "csv",
    has_headers: bool = True,
    sample_size_mb: float = 1.5,
    table_type: str = "raw",
) -> dict:
    """
    function infers and returns glue schema for csv and parquet files.
    schema are inferred using arrow
    """

    bucket, key = file_key.replace("s3://", "").split("/", 1)
    table_name = key.split("/")[2].replace("table_name=", "")

    raw_table_name = f"{table_name}_raw"

    if file_type == "csv":
        obj = boto3.resource("s3").Object(bucket, key)
        bytes_range = f"bytes=0-{int(sample_size_mb*1000000)}"
        byte_rows = obj.get(Range=bytes_range)["Body"].readlines()[:-1]

        str_rows = []
        for row in byte_rows:
            # use 'utf-8-sig' as decodes both with and without byte order mark BOM
            str_rows.append(
                [
                    _tryeval(val)
                    for val in row.decode("utf-8-sig").strip("\r\n\t").split(",")
                ]
            )

        # we don't want spaces or brackets in our column names
        col_names = [
            col.strip().replace(" ", "_").replace("(", "").replace(")", "")
            for col in str_rows[0]
        ]

        # put sample data in a dict, key with list of values for each column
        data_dict = {}
        for col_index, col_name in enumerate(col_names):
            data_dict[col_name] = [
                value[col_index] if not value[col_index] == "" else None
                for value in str_rows[1:]
            ]

        # if numeric and non-numeric values in column make string
        for key, list_values in data_dict.items():
            types = set(
                [
                    str(value).replace(".", "", 1).isdigit()
                    for value in list_values
                    if value is not None
                ]
            )
            if len(types) > 1:
                data_dict[key] = [str(value) for value in list_values]

        arrow_table = pa.Table.from_pydict(data_dict)

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
            metadata_mojap.update_column(
                {"name": col["name"], "type": "string"}
            )

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

    return metadata_glue


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
            logging.error("Unexpected error: %s" % e)
            raise
    table_name = metadata_glue["TableInput"]["Name"]
    try:
        glue_client.delete_table(DatabaseName="data_products_raw", Name=table_name)
    except ClientError:
        pass

    glue_client.create_table(**metadata_glue)
    logging.info(f"created table data_products_raw.{table_name}")


def create_curated_athena_table(
    database_name: str,
    table_name: str,
    curated_path: str,
    bucket: str,
    extraction_timestamp: str,
    account_id: str,
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
            logging.error("Unexpected error: %s" % e)
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
            logging.info(
                f"This is a new data product. Creating {database_name}.{table_name}"
            )
            start_query_execution_and_wait(
                database_name,
                account_id,
                sql_create_table_partition(
                    database_name, table_name, curated_path, extraction_timestamp
                ),
            )

            return

    partition_file_exists = does_partition_file_exist(
        bucket, database_name, table_name, extraction_timestamp
    )
    if table_exists and not partition_file_exists:
        logging.info("table does already exist but partition for timestamp does not")
        # unload query to make partitioned data
        start_query_execution_and_wait(
            "data_products_raw",
            account_id,
            sql_unload_table_partition(extraction_timestamp, table_name, curated_path),
        )

        logging.info("Updating table {0}.{1}".format(database_name, table_name))
        refresh_table_partitions(database_name, table_name, account_id)

    elif not table_exists and partition_file_exists:
        logging.info("partition data exists but glue table does not")
        table_metadata = infer_glue_schema(
            curated_path,
            database_name=database_name,
            file_type="parquet",
            table_type="curated",
        )

        glue_client.create_table(**table_metadata)
        refresh_table_partitions(database_name, table_name, account_id)
    elif not table_exists and not partition_file_exists:
        logging.info("table and partition do not exist but other curated data do")
        # unload query to make partitioned data
        start_query_execution_and_wait(
            "data_products_raw",
            account_id,
            sql_unload_table_partition(extraction_timestamp, table_name, curated_path),
        )

        table_metadata = infer_glue_schema(
            curated_path,
            database_name=database_name,
            file_type="parquet",
            table_type="curated",
        )
        glue_client.create_table(**table_metadata)
        refresh_table_partitions(database_name, table_name, account_id)

    else:
        logging.info(
            "partition for extraction_timestamp and table already exists so nothing more to be done."
        )


def clean_up_temp_tables(table_name: str) -> None:
    glue_client.delete_table(DatabaseName="data_products_raw", Name=table_name)
    logging.info(f"removed raw table data_products_raw.{table_name}")


def handler(event, context):
    bucket_name = event["detail"]["requestParameters"]["bucketName"]
    file_key = event["detail"]["requestParameters"]["key"]

    full_s3_path = os.path.join("s3://", bucket_name, file_key)
    logging.info(f"file is: {full_s3_path}")
    metadata_raw = infer_glue_schema(full_s3_path, "data_products_raw")
    config = get_data_product_config(full_s3_path)
    logging.info(f"config: {config}")
    create_raw_athena_table(metadata_raw)
    create_curated_athena_table(
        config["database_name"],
        config["table_name"],
        config["table_path_curated"],
        config["bucket"],
        config["extraction_timestamp"],
        config["account_id"],
    )
    clean_up_temp_tables(config["table_name"] + "_raw")
