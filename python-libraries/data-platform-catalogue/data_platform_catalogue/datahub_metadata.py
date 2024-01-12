import json
import logging
import os
import sys

import boto3
import datahub.emitter.mce_builder as mce_builder
from data_platform_catalogue.client import DataHubCatalogueClient
from data_platform_catalogue.entities import TableMetadata
from datahub.api.entities.dataproduct.dataproduct import DataProduct
from datahub.emitter.mcp import MetadataChangeProposalWrapper
from datahub.emitter.rest_emitter import DatahubRestEmitter
from datahub.ingestion.graph.client import DatahubClientConfig, DataHubGraph

# secrets_client = boto3.client("secretsmanager")

# jwt_secret = json.loads(
#     secrets_client.get_secret_value(SecretId=os.getenv("DATAHUB_JWT_SECRET_ARN"))[
#         "SecretString"
#     ]
# )
# jwt_token = jwt_secret["token"]


# # This is for interaction with the GraphQL API, which seems to be necessary for newer stuff like Data Products
# gms_endpoint = "https://datahub.apps-tools.development.data-platform.service.justice.gov.uk/api/gms"
# graph = DataHubGraph(DatahubClientConfig(server=gms_endpoint, token=jwt_token))


# # Imports for metadata model classes
# from datahub.metadata.schema_classes import (
#     AuditStampClass,
#     DatasetPropertiesClass,
#     DateTypeClass,
#     NumberTypeClass,
#     OtherSchemaClass,
#     SchemaFieldClass,
#     SchemaFieldDataTypeClass,
#     SchemaMetadataClass,
#     StringTypeClass,
# )

# # Create an emitter to DataHub over REST
# emitter = DatahubRestEmitter(
#     gms_server=gms_endpoint,
#     token=jwt_token,
#     timeout_sec=1,
#     connect_timeout_sec=1,
#     extra_headers={},
# )

# # Test the connection
# try:
#     print("Testing connection...")
#     emitter.test_connection()
# except Exception as err:
#     print(f"Error occurred: {err}")
#     sys.exit(1)

# print("Passed.")

# # Construct a dataset properties object
# dataset_properties = DatasetPropertiesClass(
#     description="Example table for testing",
#     customProperties={"dpia_required": "yes"},
# )

# # Construct a MetadataChangeProposalWrapper object.
# metadata_event = MetadataChangeProposalWrapper(
#     entityUrn=builder.make_dataset_urn(
#         "athena", "athena.catalog.hmpps_use_of_force_v2.statements"
#     ),
#     aspect=dataset_properties,
# )


# test_platform_instance = mce_builder.make_dataplatform_instance_urn()

# metadata_event = MetadataChangeProposalWrapper(
#     entityUrn=mce_builder.make_data_platform_urn("test_data_product")
# )


# emitter.emit(metadata_event)

# dataset_schema_properties = SchemaMetadataClass(
#     schemaName="customer",  # not used
#     platform=make_data_platform_urn("athena"),  # important <- platform must be an urn
#     version=1,  # when the source system has a notion of versioning of schemas, insert this in, otherwise leave as 0
#     hash="",  # when the source system has a notion of unique schemas identified via hash, include a hash, else leave it as empty string
#     # platformSchema: Union["EspressoSchemaClass", "OracleDDLClass", "MySqlDDLClass", "PrestoDDLClass", "KafkaSchemaClass", "BinaryJsonSchemaClass", "OrcSchemaClass", "SchemalessClass", "KeyValueSchemaClass", "OtherSchemaClass"],
#     platformSchema=OtherSchemaClass(rawSchema="__insert raw schema here__"),
#     lastModified=AuditStampClass(time=1640692800000, actor="urn:li:corpuser:ingestion"),
#     fields=[
#         SchemaFieldClass(
#             fieldPath="statements.id",
#             # type: Union["BooleanTypeClass", "FixedTypeClass", "StringTypeClass", "BytesTypeClass", "NumberTypeClass", "DateTypeClass", "TimeTypeClass", "EnumTypeClass", "NullTypeClass", "MapTypeClass", "ArrayTypeClass", "UnionTypeClass", "RecordTypeClass"],
#             type=SchemaFieldDataTypeClass(type=NumberTypeClass()),
#             nativeDataType="bigint",  # use this to provide the type of the field in the source system's vernacular
#             description="Unique identifier for the statement",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.report_id",
#             type=SchemaFieldDataTypeClass(type=NumberTypeClass()),
#             nativeDataType="bigint",
#             description="Unique identifier for the report",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.user_id",
#             type=SchemaFieldDataTypeClass(type=NumberTypeClass()),
#             nativeDataType="bigint",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.name",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.email",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.submitted_date",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="Date the statement was submitted (unknown format)",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.submitted_date",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.statement_status",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.last_training_month",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.last_training_year",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.job_start_year",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.staff_id",
#             type=SchemaFieldDataTypeClass(type=NumberTypeClass()),
#             nativeDataType="bigint",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.created_date",
#             type=SchemaFieldDataTypeClass(type=DateTypeClass()),
#             nativeDataType="timestamp",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.updated_date",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="timestamp",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.next_reminder_date",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.overdue_date",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.in_progress",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.deleted",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.removal_requested_reason",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#         SchemaFieldClass(
#             fieldPath="statements.removal_requested_date",
#             type=SchemaFieldDataTypeClass(type=StringTypeClass()),
#             nativeDataType="string",
#             description="???",
#             lastModified=AuditStampClass(
#                 time=1640692800000, actor="urn:li:corpuser:ingestion"
#             ),
#         ),
#     ],
# )

# metadata_event = MetadataChangeProposalWrapper(
#     entityUrn=builder.make_dataset_urn(
#         "athena", "athena.catalog.hmpps_use_of_force_v2.statements"
#     ),
#     aspect=dataset_schema_properties,
# )

# # Emit metadata! This is a blocking call
# emitter.emit(metadata_event)


# data_product = DataProduct(
#     id="hmpps_use_of_force",
#     display_name="Use of force",
#     domain="urn:li:domain:4414be1c-8677-4c5b-9799-f955ae9d8432",
#     description="TODO - describe the use of force data product 2",
#     assets=[
#         builder.make_dataset_urn(
#             "athena", "athena.catalog.hmpps_use_of_force_v2.statements"
#         ),
#     ],
#     owners=[{"id": "urn:li:corpuser:jdoe", "type": "BUSINESS_OWNER"}],
#     terms=["urn:li:glossaryTerm:ClientsAndAccounts.AccountBalance"],
#     tags=["urn:li:tag:adoption"],
#     properties={"lifecycle": "production", "sla": "7am every day"},
#     external_url="https://en.wikipedia.org/wiki/Sloth",
# )

# for mcp in data_product.generate_mcp(upsert=False):
#     graph.emit(mcp)


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
console = logging.StreamHandler()
console.setLevel(level=logging.DEBUG)
formatter = logging.Formatter("%(levelname)s : %(message)s")
console.setFormatter(formatter)
logger.addHandler(console)

client = DataHubCatalogueClient(jwt_token="", api_url="http://localhost:8080")

schema_fqn = "data-platform.data-product.schema"

table = TableMetadata(
    name="my_table",
    description="bla bla",
    column_details=[
        {"name": "foo", "type": "string", "description": "a"},
        {"name": "bar", "type": "int", "description": "b"},
    ],
    retention_period_in_days=365,
)

client.create_or_update_table(metadata=table, schema_fqn=schema_fqn)
