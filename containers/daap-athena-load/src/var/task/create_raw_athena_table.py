from contextlib import contextmanager
from typing import Generator

from botocore.exceptions import ClientError
from data_platform_logging import DataPlatformLogger
from infer_glue_schema import InferredMetadata


def create_raw_athena_table(
    metadata: InferredMetadata, logger: DataPlatformLogger, glue_client
) -> None:
    """
    Creates an empty athena table from the raw file pushed by
    a data producer for raw data.
    """
    database_name = metadata.database_name
    create_glue_database(glue_client, database_name, logger)

    # Create raw data table, recreating it if necessary
    table_name = metadata.table_name
    try:
        glue_client.delete_table(DatabaseName=database_name, Name=table_name)
    except ClientError:
        pass
    glue_client.create_table(**metadata.metadata_str)
    logger.info(f"created table {database_name}.{table_name}")


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


def delete_raw_athena_table(
    metadata: InferredMetadata, logger: DataPlatformLogger, glue_client
):
    glue_client.delete_table(
        DatabaseName=metadata.database_name, Name=metadata.table_name
    )
    logger.info(f"removed raw table {metadata.database_name}.{metadata.table_name}")


@contextmanager
def temporary_raw_athena_table(
    metadata: InferredMetadata, logger: DataPlatformLogger, glue_client
) -> Generator[None, None, None]:
    try:
        create_raw_athena_table(
            metadata=metadata, logger=logger, glue_client=glue_client
        )
        yield
    finally:
        delete_raw_athena_table(
            metadata=metadata, logger=logger, glue_client=glue_client
        )
