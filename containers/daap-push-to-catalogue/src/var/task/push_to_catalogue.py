import logging
import os

import boto3
from data_platform_catalogue import CatalogueClient, CatalogueError
from data_platform_catalogue import DataProductMetadata as omdProductMetadata
from data_platform_catalogue import TableMetadata


def handler(event, context):
    logger = logging.getLogger()
    metadata = event["metadata"]
    version = event["version"]
    data_product_name = event["data_product_name"]
    table_name = event["table_name"]

    logger.info(event)

    secrets_client = boto3.client("secretsmanager")
    jwt_secret = secrets_client.get_secret_value(
        SecretId=os.getenv("OPENMETADATA_JWT_SECRET_ARN")
    )
    token = jwt_secret["token"]
    openmetadata_client = CatalogueClient(
        jwt_token=token,
        api_uri=os.getenv("OPENMETADATA_DEV_API_URL"),
    )
    user_id = openmetadata_client.get_user_id(metadata["dataProductOwner"])

    if table_name is None:
        data_product = omdProductMetadata.from_data_product_metadata_dict(
            metadata=metadata, version=version, owner_id=user_id
        )
        try:
            schema_fqn = openmetadata_client.create_or_update_schema(
                metadata=data_product, database_fqn="data_platform.data_platform"
            )

        except CatalogueError:
            logger.error("error in push of metadata to openmetadata")
            response_body = {
                "catalogue_error": f"{data_product_name} failed push to catalogue"
            }
            return response_body
        else:
            response_body = {"catalogue_message": f"{schema_fqn} pushed to catalogue"}
            return response_body
    else:
        schema_fqn = f"data_platform.data_platform.{data_product_name}"
        table = TableMetadata.from_data_product_schema_dict(
            metadata=metadata, table_name=table_name
        )
        try:
            table_fqn = openmetadata_client.create_or_update_table(
                metadata=table, schema_fqn=schema_fqn
            )
        except CatalogueError:
            logger.error("error in push of table metadata to catalogue")
            response_body = {
                "catalogue_error": f"{data_product_name}.{table_name} failed push to catalogue"
            }
            return response_body
        else:
            response_body = {"catalogue_message": f"{table_fqn} pushed to catalogue"}
            return response_body
