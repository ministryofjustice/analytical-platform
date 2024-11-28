module "dms" {
  source = "../../modules/de-dms"

  environment                   = "sandbox"
  db                            = "oracle19"
  source_secrets_manager_arn    = "managed_pipelines/sandbox/oracle19"
  dms_source_server_name        = "oracle19.cn2clhldf81y.eu-west-1.rds.amazonaws.com"
  dms_source_database_name      = "oracle19"
  landing_bucket                = "mojap-land-sandbox"
  landing_bucket_folder         = "hmpps/oracle19"

  dms_replication_instance = {
    replication_instance_id = "oracle19-1-eu-west-1-sandbox"
    allocated_storage = 50
    availability_zone = "eu-west-1a"
    engine_version  = "3.5.3"
    kms_key_arn = "arn:aws:kms:eu-west-1:684969100054:key/a526d2a0-59e6-457f-89eb-524790ea3a30"
    multi_az = false
    replication_instance_class = "dms.t2.micro"
    vpc_security_group_ids = ["sg-0b767b59a7f79c72c"]
    subnet_ids = ["subnet-063c9bf0b02171cc5", "subnet-01f59f6f6fe77a6d7", "subnet-00f37258fadd49a44"]
  }
}

import {
  to = module.dms.aws_dms_replication_subnet_group.replication_subnet_group
  id = "eu-west-1-sandbox"
}

import {
  to = module.dms.aws_dms_endpoint.source
  id = "oracle19-source-eu-west-1-sandbox"
}

import {
  to = module.dms.aws_iam_role.dms
  id = "oracle19-dms-sandbox"
}

import {
  to = module.dms.aws_iam_role_policy.dms
  id = "oracle19-dms-sandbox:oracle19-dms-sandbox"
}

import {
  to = module.dms.aws_dms_s3_endpoint.s3_target
  id = "oracle19-target-eu-west-1-sandbox"
}

import {
  to = module.dms.aws_dms_replication_instance.instance
  id = "oracle19-1-eu-west-1-sandbox"
}
