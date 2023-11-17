import boto3
from botocore.exceptions import ClientError
from data_platform_logging import DataPlatformLogger

glue_client = boto3.client("glue")


def create_glue_database(glue_client, database_name, logger):
    """If a glue database doesn't exist, create a glue database"""
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
            raise


def delete_glue_table(
    data_product_name: str, table_name: str, logger: DataPlatformLogger
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


def delete_glue_database(
    data_product_name: str, logger: DataPlatformLogger
) -> str | None:
    """deletes a glue database and all associated tables"""
    try:
        glue_client.get_database(Name=data_product_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            error_message = f"Could not locate glue database '{data_product_name}'"
            logger.error(error_message)
            raise ValueError(error_message)
        else:
            raise
    else:
        glue_client.delete_database(Name=data_product_name)
    return None
