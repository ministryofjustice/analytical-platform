import boto3
from botocore.exceptions import ClientError
from data_platform_logging import DataPlatformLogger

glue_client = boto3.client("glue")


def delete_glue_table(
    database_name: str, table_name: str, logger: DataPlatformLogger
) -> str | None:
    """Attempts to locate and delete a glue table for the given data product"""
    try:
        glue_client.get_table(DatabaseName=database_name, Name=table_name)
    except ClientError as e:
        if e.response["Error"]["Code"] == "EntityNotFoundException":
            error_message = f"Could not locate glue table '{table_name}' in database '{database_name}'"
            return error_message
        else:
            raise
    else:
        result = glue_client.delete_table(DatabaseName=database_name, Name=table_name)
        return result
