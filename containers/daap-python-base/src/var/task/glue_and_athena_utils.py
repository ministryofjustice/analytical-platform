import time

import boto3
from botocore.client import BaseClient
from botocore.exceptions import ClientError
from data_platform_logging import DataPlatformLogger

glue_client = boto3.client("glue")
athena_client = boto3.client("athena")


def create_database(
    database_name: str,
    logger: DataPlatformLogger,
    db_meta: dict | None = None,
    client: BaseClient = None,
) -> None:
    """If a glue database doesn't exist, create a glue database"""
    if client is None:
        client = glue_client
    try:
        client.get_database(Name=database_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            if not db_meta:
                db_meta = {
                    "DatabaseInput": {
                        "Description": "database for {} products".format(database_name),
                        "Name": database_name,
                    }
                }
            client.create_database(**db_meta)
        else:
            logger.error("Unexpected error: %s" % e)
            raise


def get_database(database_name: str, logger: DataPlatformLogger) -> dict | None:
    """Get the database for the given database name"""
    try:
        database = glue_client.get_database(Name=database_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            logger.error(f"Database name {database_name} not found.")
            return None
        else:
            logger.error(f"Unexpected error: {e}")
            raise
    else:
        return database


def database_exists(database_name: str, logger: DataPlatformLogger) -> bool:
    """Check if a database exists with the given name"""
    return get_database(database_name=database_name, logger=logger) is not None


def delete_database(database_name: str, logger: DataPlatformLogger) -> None:
    """Delete a glue database with the given database name"""
    try:
        glue_client.delete_database(Name=database_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            logger.info(f"Glue database '{database_name}' not found.")
        else:
            logger.error("Unexpected error: %s" % e)
            raise


def clone_database(
    existing_database_name: str, new_database_name: str, logger: DataPlatformLogger
) -> None:
    """
    Make a copy of a database with a new name, copying all metadata except ids and timestamps.

    This function makes a new empty database with the same metadata definition, note it does NOT copy any of the
    tables or data within a database.
    """
    current_database = get_database(database_name=existing_database_name, logger=logger)
    if current_database is None:
        raise ValueError(f"Database {existing_database_name} does not exist")

    current_tables = list_tables(database_name=existing_database_name, logger=logger)

    database = current_database["Database"]
    database_keys_to_keep = ["Name", "Description", "LocationUri", "Parameters"]
    db_meta = {k: v for k, v in database.items() if k in database_keys_to_keep}
    db_meta["Name"] = new_database_name
    db_meta = {"DatabaseInput": {**db_meta}}
    logger.info(str(db_meta))

    create_glue_database(
        database_name=new_database_name,
        glue_client=glue_client,
        logger=logger,
        db_meta=db_meta,
    )

    table_keys_to_keep = [
        "Name",
        "Description",
        "Owner",
        "Retention",
        "StorageDescriptor",
        "PartitionKeys",
        "ViewOriginalText",
        "ViewExpandedText",
        "TableType",
        "Parameters",
        "TargetTable",
    ]

    if not current_tables:
        return

    for table in current_tables:
        table_meta = {k: v for k, v in table.items() if k in table_keys_to_keep}
        table_meta = {"TableInput": {**table_meta}}
        create_table(
            database_name=new_database_name, logger=logger, table_meta=table_meta
        )


def create_table(
    database_name: str,
    logger: DataPlatformLogger,
    table_name: str | None = None,
    table_meta: dict | None = None,
) -> None:
    """Create a glue table on the given database."""
    if not table_meta:
        table_meta = {"TableInput": {"Name": table_name}}
    try:
        glue_client.create_table(DatabaseName=database_name, **table_meta)
    except ClientError as e:
        if e.response["Error"]["Code"] == "AlreadyExistsException":
            logger.error(f"Table {table_meta['TableInput']['Name']} already exists.")
        else:
            logger.error("Unexpected error: %s" % e)
            raise

    return None


def get_table(
    database_name: str, table_name: str, logger: DataPlatformLogger
) -> dict | None:
    """Get the table for the given table name and database"""
    try:
        table = glue_client.get_table(DatabaseName=database_name, Name=table_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            logger.error(
                f"Table name {table_name} not found in database {database_name}."
            )
            return None
        else:
            logger.error("Unexpected error: %s" % e)
            raise
    else:
        return table


def list_tables(database_name: str, logger: DataPlatformLogger) -> list[dict]:
    """Get the table for the given table name and database"""
    try:
        tables = glue_client.get_tables(DatabaseName=database_name)
        return tables["TableList"]
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            logger.error(f"Database name {database_name} not found.")
            return []
        else:
            logger.error("Unexpected error: %s" % e)
            raise
    else:
        return tables


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


def delete_table(
    database_name: str,
    table_name: str,
    logger: DataPlatformLogger,
) -> None:
    """Attempts to locate and delete a glue table for the given data product"""
    try:
        glue_client.get_table(DatabaseName=database_name, Name=table_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            error_message = f"Could not locate glue table '{table_name}' in database '{database_name}'"
            logger.error(error_message)
            raise ValueError(error_message)
        else:
            logger.error("Unexpected error: %s" % e)
            raise
    else:
        result = glue_client.delete_table(DatabaseName=database_name, Name=table_name)
        logger.debug(str(result))


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


def get_glue_database(*args, **kwargs):
    """
    Alias for backwards compatability
    """
    return get_database(*args, **kwargs)


def delete_glue_table(
    data_product_name: str,
    table_name: str,
    logger: DataPlatformLogger,
):
    """
    Alias for backwards compatability
    """
    return delete_table(
        database_name=data_product_name, table_name=table_name, logger=logger
    )


def create_glue_database(
    glue_client: BaseClient,
    database_name: str,
    logger: DataPlatformLogger,
    db_meta: dict | None = None,
):
    """
    Alias for backwards compatability
    """
    return create_database(
        database_name=database_name,
        logger=logger,
        db_meta=db_meta,
        client=glue_client,
    )


def delete_glue_database(*args, **kwargs):
    """
    Alias for backwards compatability
    """
    return delete_table(*args, **kwargs)
