import time

import boto3
from botocore.client import BaseClient
from botocore.exceptions import ClientError
from data_platform_logging import DataPlatformLogger

glue_client = boto3.client("glue")
athena_client = boto3.client("athena")


def create_glue_database(
    glue_client: BaseClient,
    database_name: str,
    logger: DataPlatformLogger,
    db_meta: dict | None = None,
):
    """If a glue database doesn't exist, create a glue database"""
    try:
        glue_client.get_database(Name=database_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            if not db_meta:
                db_meta = {
                    "DatabaseInput": {
                        "Description": "database for {} products".format(database_name),
                        "Name": database_name,
                    }
                }
            glue_client.create_database(**db_meta)
        else:
            logger.error("Unexpected error: %s" % e)
            raise


def delete_glue_database(database_name: str, logger: DataPlatformLogger) -> None:
    """Delete a glue database with the given database name"""
    try:
        glue_client.delete_database(Name=database_name)
    except glue_client.exceptions.EntityNotFoundException:
        logger.info(f"Glue database '{database_name}' not found.")


def delete_glue_table(
    data_product_name: str,
    table_name: str,
    logger: DataPlatformLogger,
) -> str | None:
    """Attempts to locate and delete a glue table for the given data product"""
    try:
        glue_client.get_table(DatabaseName=data_product_name, Name=table_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            error_message = f"Could not locate glue table '{table_name}' in database '{data_product_name}'"
            logger.error(error_message)
            raise ValueError(error_message)
        else:
            raise
    else:
        result = glue_client.delete_table(
            DatabaseName=data_product_name, Name=table_name
        )
        return result


def refresh_table_partitions(
    database_name: str, table_name: str, workgroup: str = "data_product_workgroup"
) -> None:
    """
    Refreshes partitions for a given table
    """
    athena_client.start_query_execution(
        QueryString=f"MSCK REPAIR TABLE {database_name}.{table_name}",
        WorkGroup=workgroup,
    )


def table_exists(database_name: str, table_name: str) -> bool:
    """
    Check if a given athena table exists in the glue catalog
    """
    try:
        glue_client.get_table(
            DatabaseName=database_name,
            Name=table_name,
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            return False
        else:
            raise
    return True


def start_query_execution_and_wait(
    database_name: str,
    sql: str,
    logger: DataPlatformLogger,
    workgroup: str = "data_product_workgroup",
) -> str:
    """
    runs query for given sql and waits for completion returning the query id
    of the executed query
    """

    try:
        res = athena_client.start_query_execution(
            QueryString=sql,
            QueryExecutionContext={"Database": database_name},
            WorkGroup=workgroup,
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "InvalidRequestException":
            logger.error(f"This sql caused an error: {sql}")
            raise ValueError(e)
        else:
            logger.error(f"unexpected error: {e}")
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
                query_id,
                response["QueryExecution"]["Status"].get("StateChangeReason"),
            )
        )
        raise ValueError(response["QueryExecution"]["Status"].get("StateChangeReason"))

    return query_id
