module "state_locking" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.2.0"

  name = "global-tf-state-aqsvzyd5u9-locks"
}

import {
  to = module.state_locking.aws_dynamodb_table.this[0]
  id = "global-tf-state-aqsvzyd5u9-locks"
}
