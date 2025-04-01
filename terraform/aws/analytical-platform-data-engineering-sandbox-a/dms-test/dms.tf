data "aws_availability_zones" "available" {}

module "dms" {
  source = "../../modules/data-engineering/dms"

  environment = local.tags.environment-name
  vpc_id      = module.vpc.vpc_id
  db          = aws_db_instance.dms_test.identifier

  dms_replication_instance = {
    replication_instance_id    = aws_db_instance.dms_test.identifier
    subnet_ids                 = module.vpc.private_subnets
    subnet_group_name          = local.name
    allocated_storage          = 20
    availability_zone          = data.aws_availability_zones.available.names[0]
    engine_version             = "3.5.4"
    multi_az                   = false
    replication_instance_class = "dms.t3.medium"
    inbound_cidr               = module.vpc.vpc_cidr_block
  }

  dms_source = {
    engine_name                 = "oracle"
    secrets_manager_arn         = "arn:aws:secretsmanager:eu-west-1:684969100054:secret:dms-test-migration-user-syaF4T"
    sid                         = aws_db_instance.dms_test.db_name
    extra_connection_attributes = "addSupplementalLogging=N;useBfile=Y;useLogminerReader=N;"
    cdc_start_time              = "2025-02-21T12:15:00Z"
  }

  replication_task_id = {
    full_load = "${aws_db_instance.dms_test.identifier}-full-load"
    cdc       = "${aws_db_instance.dms_test.identifier}-cdc"
  }

  dms_mapping_rules = file("${path.module}/test_mappings.json")

  tags = local.tags
}
