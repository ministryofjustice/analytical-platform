module "state_locking" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.2.0"

  name = "global-tf-state-aqsvzyd5u9-locks"
}

import {
  to = module.state_locking.aws_dynamodb_table.this[0]
  id = "global-tf-state-aqsvzyd5u9-locks"
}
