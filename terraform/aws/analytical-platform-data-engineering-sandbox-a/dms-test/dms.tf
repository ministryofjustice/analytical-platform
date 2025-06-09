data "aws_availability_zones" "available" {}
resource "aws_secretsmanager_secret" "dms_sandbox_secret" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "dms-sandbox-secret"
  kms_key_id = module.dms_test_kms.key_arn
}

module "test_dms_implementation" {
  source = "github.com/ministryofjustice/terraform-dms-module?ref=intial_branch"

  vpc_id      = module.vpc.vpc_id
  environment = local.tags.environment-name

  db = aws_db_instance.dms_test.identifier
  slack_webhook_secret_id = aws_secretsmanager_secret.slack_webhook.id
  dms_replication_instance = {
    replication_instance_id    = "test-dms"
    subnet_ids                 = module.vpc.private_subnets
    subnet_group_name          = "test-dms"
    allocated_storage          = 20
    availability_zone          = data.aws_availability_zones.available.names[0]
    engine_version             = "3.5.4"
    kms_key_arn                = module.dms_test_kms.key_arn
    multi_az                   = false
    replication_instance_class = "dms.t3.large"
    inbound_cidr               = module.vpc.vpc_cidr_block
    apply_immediately          = true
  }

  dms_source = {
    engine_name                 = "oracle"
    secrets_manager_arn         = aws_secretsmanager_secret.dms_sandbox_secret.arn
    secrets_manager_kms_arn     = module.dms_test_kms.key_arn
    sid                         = aws_db_instance.dms_test.db_name
    extra_connection_attributes = "addSupplementalLogging=N;useBfile=Y;useLogminerReader=N;"
    cdc_start_time              = "2025-04-02T12:00:00Z"
  }

  replication_task_id = {
    full_load = "test-dms-full-load"
    cdc       = "test-dms-cdc"
  }

  dms_mapping_rules = {
    bucket = aws_s3_object.mappings.bucket
    key    = aws_s3_object.mappings.key
  }
  #output_bucket         = module.test_dms_rawhist

  tags = local.tags

  # create_premigration_assessement_resources = false
  # write_metadata_to_glue_catalog            = false
  # retry_failed_after_recreate_metadata      = true
  # valid_files_mutable                       = true
  glue_catalog_arn = "arn:aws:glue:eu-west-1:684969100054:catalog"
}
