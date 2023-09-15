from botocore.exceptions import ClientError
from data_platform_logging import DataPlatformLogger


def create_raw_athena_table(
    metadata_glue: dict,
    logger: DataPlatformLogger,
    glue_client,
    bucket,
    s3_security_opts,
) -> None:
    """
    Creates an empty athena table from the raw file pushed by
    a data producer for raw data.
    """
    database_name = metadata_glue["DatabaseName"]
    create_glue_database(glue_client, database_name, logger, bucket, s3_security_opts)

    # Create raw data table, recreating it if necessary
    table_name = metadata_glue["TableInput"]["Name"]
    try:
        glue_client.delete_table(DatabaseName=database_name, Name=table_name)
    except ClientError:
        pass
    glue_client.create_table(**metadata_glue)
    logger.info(f"created table {database_name}.{table_name}")


def create_glue_database(glue_client, database_name, logger, bucket, s3_security_opts):
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
            logger.write_log_dict_to_s3_json(bucket=bucket, **s3_security_opts)
            raise
