import boto3
from botocore.exceptions import ClientError
from data_platform_logging import DataPlatformLogger

glue_client = boto3.client("glue")


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
            raise ValueError(e)
        else:
            error_message = f"Unexpected ClientError: {e.response['Error']['Code']}"
            logger.error(error_message)
            raise ValueError(e)
    else:
        glue_client.delete_table(DatabaseName=data_product_name, Name=table_name)
        logger.info(f"{table_name} table deleted")
