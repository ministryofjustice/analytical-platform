module "preprod_dms_oasys" {
  source      = "github.com/ministryofjustice/terraform-dms-module?ref=fb85692a4ad7b662a909fd56e543dc44f071fea7"
  vpc_id      = module.vpc.vpc_id
  environment = var.tags.environment-name

  db                      = "oasys-preprod"
  slack_webhook_secret_id = aws_secretsmanager_secret.slack_webhook.id
  output_key_prefix       = "hmpps/oasys"
  output_key_suffix       = "-tf"
  output_bucket           = "mojap-raw-hist-preprod"

  dms_replication_instance = {
    replication_instance_id    = "oasys-preprod"
    subnet_ids                 = module.vpc.private_subnets
    subnet_group_name          = "oasys-preprod"
    allocated_storage          = 50
    availability_zone          = data.aws_availability_zones.available.names[0]
    engine_version             = "3.5.4"
    kms_key_arn                = module.dms_preprod_kms.key_arn
    multi_az                   = false
    replication_instance_class = "dms.t3.medium"
    inbound_cidr               = "192.0.2.0/32" # test unassigned
    apply_immediately          = true
  }
  dms_source = {
    engine_name             = "oracle"
    secrets_manager_arn     = aws_secretsmanager_secret.oasys_preprod_secret.arn
    secrets_manager_kms_arn = module.dms_preprod_kms.key_arn
    sid                     = "OASYS_TAF"

    extra_connection_attributes = "addSupplementalLogging=N;additionalArchivedLogDestId=2;allowSelectNestedTables=True;archivedLogDestId=1;asm_server=10.27.4.145/+ASM;asm_user=AWS;parallelASMReadThreads=8;readAheadBlocks=200000;useBfile=Y;useLogminerReader=N;"
    cdc_start_time              = "2025-06-24T12:00:00Z"
  }
  replication_task_id = {
    full_load = "oasys-preprod-full-load"
    cdc       = "oasys-preprod-cdc"
  }
  dms_mapping_rules = {
    bucket = "mojap-data-engineering-prod-table-mappings-metadata-preprod"
    key    = "preprod/oasys/table_mappings.json"
  }

  tags = merge(
    { "managed-by" = "Terraform" },
    var.tags
  )

  glue_catalog_arn = "arn:aws:glue:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:catalog"
}
