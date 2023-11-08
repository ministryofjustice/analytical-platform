import json
import structlog
import logging
import os

import boto3
from data_platform_catalogue import CatalogueClient, CatalogueError
from data_platform_catalogue import DataProductMetadata as omdProductMetadata
from data_platform_catalogue import TableMetadata


def handler(event, context):
    # can't use daap-python-base as it's python 3.11 and need 3.10 for
    # data_platform_catalogue, hence we can't use DataPlatformLogger here
    structlog.configure(
    wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
    processors=[
        structlog.processors.EventRenamer(to="message"),
        structlog.processors.TimeStamper(
            fmt="%Y-%m-%d %H:%M:%S", key="date_time"
        ),
        structlog.processors.add_log_level,
        structlog.processors.dict_tracebacks,
        structlog.processors.CallsiteParameterAdder(
            parameters={structlog.processors.CallsiteParameter.FUNC_NAME},
            additional_ignores=["data_platform_logging"],
        ),
        structlog.processors.JSONRenderer(),
    ],
)

    metadata = event["metadata"]
    version = event.get("version")
    data_product_name = event["data_product_name"]
    table_name = event.get("table_name")

    logger = structlog.get_logger(**{"data_product_name":data_product_name, "table_name": table_name})
    logger.info(f"input_event: {event}")

    secrets_client = boto3.client("secretsmanager")
    jwt_secret = json.loads(
        secrets_client.get_secret_value(
            SecretId=os.getenv("OPENMETADATA_JWT_SECRET_ARN")
        )["SecretString"]
    )
    token = jwt_secret["token"]
    openmetadata_client = CatalogueClient(
        jwt_token=token,
        api_uri=os.getenv("OPENMETADATA_DEV_API_URL"),
    )

    if not openmetadata_client.is_healthy():
        logger.error("error in push of table metadata to catalogue")
        return {
            "catalogue_error": f"Problem establishing connection to openmetadata for {data_product_name}."
        }
    if table_name is None:
        user_id = openmetadata_client.get_user_id(metadata["dataProductOwner"])
        data_product = omdProductMetadata.from_data_product_metadata_dict(
            metadata=metadata, version=version, owner_id=user_id
        )
        # We now want to create a generic schema level in openmetadata as below
        metadata["name"] = "Tables"
        metadata["description"] = f"All the tables contained within {data_product.name}"
        data_product_schema = omdProductMetadata.from_data_product_metadata_dict(
            metadata=metadata, version="v1.0", owner_id=user_id
        )
        try:
            database_fqn = openmetadata_client.create_or_update_database(
                metadata=data_product, service_fqn="data_platform"
            )
            # create the generic schema level
            openmetadata_client.create_or_update_schema(
                metadata=data_product_schema, database_fqn=database_fqn
            )

        except CatalogueError:
            logger.error("error in push of metadata to openmetadata")
            response_body = {
                "catalogue_error": f"{data_product_name} failed push to catalogue"
            }
            return response_body
        else:
            response_body = {"catalogue_message": f"{database_fqn} pushed to catalogue"}
            return response_body
    else:
        table = TableMetadata.from_data_product_schema_dict(
            metadata=metadata, table_name=table_name
        )
        try:
            table_fqn = openmetadata_client.create_or_update_table(
                metadata=table, schema_fqn=f"data_platform.{data_product_name}.Tables"
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


