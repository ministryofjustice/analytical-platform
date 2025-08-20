module "prod_dms_oasys" {
  source      = "github.com/ministryofjustice/terraform-dms-module?ref=a8f5d7d6f4984d3d7cf62d1410d49512a31f3556"
  vpc_id      = module.vpc.vpc_id
  environment = var.tags.environment-name

  db                      = "oasys-prod"
  slack_webhook_secret_id = aws_secretsmanager_secret.slack_webhook.id
  output_key_prefix       = "hmpps/oasys"
  output_key_suffix       = "-tf"
  output_bucket           = "mojap-raw-hist"

  dms_replication_instance = {
    replication_instance_id    = "oasys-prod"
    subnet_ids                 = module.vpc.private_subnets
    subnet_group_name          = "oasys-prod"
    allocated_storage          = 100
    availability_zone          = data.aws_availability_zones.available.names[0]
    engine_version             = "3.5.4"
    kms_key_arn                = module.dms_prod_kms.key_arn
    multi_az                   = false
    replication_instance_class = "dms.r6i.2xlarge"
    inbound_cidr               = "192.0.2.0/32" # test unassigned
    apply_immediately          = true
  }
  dms_source = {
    engine_name             = "oracle"
    secrets_manager_arn     = aws_secretsmanager_secret.oasys_prod_secret.arn
    secrets_manager_kms_arn = module.dms_prod_kms.key_arn
    sid                     = "DROASYS"

    extra_connection_attributes = "addSupplementalLogging=N;additionalArchivedLogDestId=2;allowSelectNestedTables=True;archivedLogDestId=1;asm_server=db-b.oasys.service.justice.gov.uk/+ASM;asm_user=AWS;parallelASMReadThreads=8;readAheadBlocks=200000;useBfile=Y;useLogminerReader=N;"
    cdc_start_time              = "2025-06-24T12:00:00Z"
  }
  replication_task_id = {
    full_load = "oasys-prod-full-load"
    cdc       = "oasys-prod-cdc"
  }
  dms_mapping_rules = {
    bucket = "mojap-data-engineering-prod-table-mappings-metadata-prod"
    key    = "prod/oasys/table_mappings.json"
  }

  tags = merge(
    { "managed-by" = "Terraform" },
    var.tags
  )

  glue_catalog_arn      = "arn:aws:glue:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:catalog"
  glue_catalog_role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/data-engineering-probation-glue"
}

module "prod_dms_delius" {
  source      = "github.com/ministryofjustice/terraform-dms-module?ref=a8f5d7d6f4984d3d7cf62d1410d49512a31f3556"
  vpc_id      = module.vpc.vpc_id
  environment = var.tags.environment-name

  db                      = "delius-prod"
  slack_webhook_secret_id = aws_secretsmanager_secret.prod_slack_webhook.id
  output_key_prefix       = "hmpps/delius"
  output_key_suffix       = "-tf"
  output_bucket           = "mojap-raw-hist"

  dms_replication_instance = {
    replication_instance_id    = "delius-prod"
    subnet_ids                 = module.vpc.private_subnets
    subnet_group_name          = "delius-prod"
    allocated_storage          = 200
    availability_zone          = data.aws_availability_zones.available.names[0]
    engine_version             = "3.5.4"
    kms_key_arn                = module.dms_prod_kms.key_arn
    multi_az                   = false
    replication_instance_class = "dms.r6i.2xlarge"
    inbound_cidr               = "192.0.2.0/32" # test unassigned
    apply_immediately          = true
  }
  dms_source = {
    engine_name             = "oracle"
    secrets_manager_arn     = aws_secretsmanager_secret.delius_prod_secret.arn
    secrets_manager_kms_arn = module.dms_prod_kms.key_arn
    sid                     = "prdndas2"

    extra_connection_attributes = "addSupplementalLogging=N;additionalArchivedLogDestId=3;allowSelectNestedTables=True;archivedLogDestId=1;asm_server=delius-db-3.probation.service.justice.gov.uk/+ASM;asm_user=delius_analytics_platform;parallelASMReadThreads=8;readAheadBlocks=200000;useBfile=Y;useLogminerReader=N;"
    cdc_start_time              = "2025-06-24T12:00:00Z"
  }
  replication_task_id = {
    full_load = "delius-prod-full-load"
    cdc       = "delius-prod-cdc"
  }
  dms_mapping_rules = {
    bucket = "mojap-data-engineering-prod-table-mappings-metadata-prod"
    key    = "prod/delius/table_mappings.json"
  }

  tags = merge(
    { "managed-by" = "Terraform" },
    var.tags
  )

  glue_catalog_arn      = "arn:aws:glue:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:catalog"
  glue_catalog_role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/data-engineering-probation-glue"
}
