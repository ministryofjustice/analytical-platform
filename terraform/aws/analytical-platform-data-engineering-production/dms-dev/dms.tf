module "dev_dms_oasys" {
  # checkov:skip=CKV_TF_1: Skipping because currently want to reference a branch whilst making changes to the dms module. Will update once dms module is stable.
  # checkov:skip=CKV_TF_2: Skipping as waiting for dms module to be stable before making a release.

  source      = "github.com/ministryofjustice/terraform-dms-module?ref=a8f5d7d6f4984d3d7cf62d1410d49512a31f3556"
  vpc_id      = module.vpc.vpc_id
  environment = var.tags.environment-name

  db                      = "oasys-dev"
  slack_webhook_secret_id = aws_secretsmanager_secret.slack_webhook.id
  output_key_prefix       = "hmpps/oasys"
  output_key_suffix       = "-tf"
  output_bucket           = "mojap-raw-hist-dev"

  dms_replication_instance = {
    replication_instance_id    = "oasys-dev"
    subnet_ids                 = module.vpc.private_subnets
    subnet_group_name          = "oasys-dev"
    allocated_storage          = 50
    availability_zone          = data.aws_availability_zones.available.names[0]
    engine_version             = "3.5.4"
    kms_key_arn                = module.dms_dev_kms.key_arn
    multi_az                   = false
    replication_instance_class = "dms.t3.medium"
    inbound_cidr               = "192.0.2.0/32" # test unassigned
    apply_immediately          = true
  }
  dms_source = {
    engine_name             = "oracle"
    secrets_manager_arn     = aws_secretsmanager_secret.oasys_dev_secret.arn
    secrets_manager_kms_arn = module.dms_dev_kms.key_arn
    sid                     = "OASYS_TAF"

    extra_connection_attributes = "addSupplementalLogging=N;additionalArchivedLogDestId=2;allowSelectNestedTables=True;archivedLogDestId=1;asm_server=10.26.12.211/+ASM;asm_user=AWS;parallelASMReadThreads=8;readAheadBlocks=200000;useBfile=Y;useLogminerReader=N;"
    cdc_start_time              = "2025-04-25T12:00:00Z"
  }
  replication_task_id = {
    full_load = "oasys-dev-full-load"
    cdc       = "oasys-dev-cdc"
  }
  dms_mapping_rules = {
    bucket = "mojap-data-engineering-production-table-mappings-metadata-dev"
    key    = "dev/oasys/table_mappings.json"
  }

  tags = merge(
    { "managed-by" = "Terraform" },
    var.tags
  )

  glue_catalog_arn      = "arn:aws:glue:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:catalog"
  glue_catalog_role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/data-engineering-probation-glue"
}
