from curated_data.curated_data_loader import CuratedDataLoader
from data_platform_logging import DataPlatformLogger
from data_platform_paths import BucketPath, QueryTable
from glue_and_athena_utils import table_exists as te


class TableMissingForExistingDataProduct(Exception):
    pass


def create_curated_athena_table(
    data_product_element,
    raw_data_table: QueryTable,
    load_timestamp,
    metadata,
    logger: DataPlatformLogger,
    athena_client,
    s3_client,
    glue_client,
):
    """
    creates curated parquet file from raw file and updates table
    to include latest timestamp partition from raw file uploaded.
    Loads data as a string into the raw athena table, then casts
    it to it's inferred type in the curated table with a timestamp.
    """
    loader = CuratedDataLoader(
        column_metadata=metadata["TableInput"]["StorageDescriptor"]["Columns"],
        table_path=data_product_element.curated_data_prefix.uri,
        table=data_product_element.curated_data_table,
        athena_client=athena_client,
        glue_client=glue_client,
        logger=logger,
    )

    # table_exists = loader.table_exists()
    table_exists = te(
        database_name=loader.curated_data_table.database,
        table_name=loader.curated_data_table.name,
    )

    partition_file_exists = does_partition_file_exist(
        data_product_element.curated_data_prefix,
        load_timestamp,
        logger=logger,
        s3_client=s3_client,
    )

    if table_exists and partition_file_exists:
        logger.info(
            "partition for load_timestamp and table already exists so nothing more to be done."
        )
        return

    if table_exists:
        logger.info("Table exists but partition does not")
        loader.ingest_raw_data(
            raw_data_table=raw_data_table, load_timestamp=load_timestamp
        )
        return

    if (
        s3_client.list_objects_v2(
            Bucket=data_product_element.curated_data_prefix.bucket,
            Prefix=data_product_element.curated_data_prefix.key,
        )["KeyCount"]
        == 0
    ):
        logger.info("This is a new data product.")
        loader.create_for_new_data_product(
            raw_data_table=raw_data_table, load_timestamp=load_timestamp
        )
        return

    logger.error(
        f"{loader.curated_data_table} does not exist,"
        f" but files exist in {loader.curated_table_path}."
        " Run reload_data_product to recreate the data product before continuing."
    )
    raise TableMissingForExistingDataProduct()


def does_partition_file_exist(
    curated_data_prefix: BucketPath,
    timestamp: str,
    logger: DataPlatformLogger,
    s3_client,
) -> bool:
    """
    returns bool indicating whether the extraction timestamp for
    a data product already exists
    """

    paginator = s3_client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(
        Bucket=curated_data_prefix.bucket, Prefix=curated_data_prefix.key
    )
    response = []
    try:
        for page in page_iterator:
            response += page["Contents"]
    except KeyError as e:
        logger.info(
            f"No {e} key found at data product curated path – the database"
            " doesn't exist and will be created"
        )

    ts_exists = any(f"load_timestamp={timestamp}" in i["Key"] for i in response)
    logger.info(f"load_timestamp={timestamp} exists = {ts_exists}")

    return ts_exists
