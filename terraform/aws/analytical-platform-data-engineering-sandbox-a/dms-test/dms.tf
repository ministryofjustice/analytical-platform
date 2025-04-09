data "aws_availability_zones" "available" {}

# module "dms" {
#   source = "../../modules/data-engineering/dms"

#   environment = local.tags.environment-name
#   vpc_id      = module.vpc.vpc_id
#   db          = aws_db_instance.dms_test.identifier

#   dms_replication_instance = {
#     replication_instance_id    = aws_db_instance.dms_test.identifier
#     subnet_ids                 = module.vpc.private_subnets
#     subnet_group_name          = local.name
#     allocated_storage          = 20
#     availability_zone          = data.aws_availability_zones.available.names[0]
#     engine_version             = "3.5.4"
#     multi_az                   = false
#     replication_instance_class = "dms.t3.medium"
#     inbound_cidr               = module.vpc.vpc_cidr_block
#   }

#   dms_source = {
#     engine_name                 = "oracle"
#     secrets_manager_arn         = "arn:aws:secretsmanager:eu-west-1:684969100054:secret:dms-test-migration-user-syaF4T"
#     sid                         = aws_db_instance.dms_test.db_name
#     extra_connection_attributes = "addSupplementalLogging=N;useBfile=Y;useLogminerReader=N;"
#     cdc_start_time              = "2025-02-21T12:15:00Z"
#   }

#   replication_task_id = {
#     full_load = "${aws_db_instance.dms_test.identifier}-full-load"
#     cdc       = "${aws_db_instance.dms_test.identifier}-cdc"
#   }

#   dms_mapping_rules = file("${path.module}/test_mappings.json")

#   tags = local.tags
# }

module "test_dms_implementation" {

    source      = "github.com/ministryofjustice/terraform-dms-module?ref=intial_branch"
    vpc_id      = module.vpc.vpc_id
    environment = local.tags.environment-name

    db          = aws_db_instance.dms_test.identifier

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
        secrets_manager_arn         = "arn:aws:secretsmanager:eu-west-1:684969100054:secret:dms-test-migration-user-syaF4T"
        secrets_manager_kms_arn     = module.dms_test_kms.key_arn
        sid                         = aws_db_instance.dms_test.db_name
        extra_connection_attributes = "addSupplementalLogging=N;useBfile=Y;useLogminerReader=N;"
        cdc_start_time              = "2025-04-02T12:00:00Z"
    }
    replication_task_id = {
      full_load =  "test-dms-full-load"
      cdc = "test-dms-cdc"
    }
    dms_mapping_rules     = "test_mappings.json"
    #output_bucket         = module.test_dms_rawhist

    tags = local.tags

    # create_premigration_assessement_resources = false
    # write_metadata_to_glue_catalog            = false
    # retry_failed_after_recreate_metadata      = true
    # valid_files_mutable                       = true
    glue_catalog_arn                          = "arn:aws:glue:eu-west-1:684969100054:catalog"
}