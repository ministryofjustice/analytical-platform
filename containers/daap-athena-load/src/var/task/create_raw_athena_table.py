from botocore.exceptions import ClientError
from data_platform_logging import DataPlatformLogger


def create_raw_athena_table(
    metadata_glue: dict, logger: DataPlatformLogger, glue_client
) -> None:
    """
    Creates an empty athena table from the raw file pushed by
    a data producer for raw data. All column types are string.
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
