module "dms" {
  source = "../../modules/de-dms"

  environment                   = "sandbox"
  db                            = "delius"
  source_secrets_manager_arn    = "managed_pipelines/sandbox/oracle19"
  dms_source_server_name        = "oracle19.cn2clhldf81y.eu-west-1.rds.amazonaws.com"
  dms_source_database_name      = "ORACLE19"
  dms_replication_instance_name = "delius-1-eu-west-1-sandbox"
  dms_replication_subnet_ids    = ["subnet-063c9bf0b02171cc5", "subnet-01f59f6f6fe77a6d7", "subnet-00f37258fadd49a44"]
  landing_bucket                = "mojap-land-sandbox"
  landing_bucket_folder         = "hmpps/delius"
}

import {
  to = module.dms.aws_dms_replication_subnet_group.replication_subnet_group
  id = "eu-west-1-sandbox"
}
