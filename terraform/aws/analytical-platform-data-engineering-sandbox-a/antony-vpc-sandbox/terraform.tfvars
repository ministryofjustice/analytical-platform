tags = {
  Environment = "antony-vpc-sandbox"
  Project     = "analytical-platform-data-engineering-sandbox-a"
  Terraform   = "true"
  Name        = "antony-vpc-sandbox"
  nuke        = "true"
}

vpc_default_sg_id   = "sg-0a1b2c3d45e6f7g8h"
database_subnet_ids = ["subnet-0bb1c79de3EXAMPLE", "subnet-1bb1c79de3EXAMPLE", "subnet-2bb1c79de3EXAMPLE"]
kms_key_arn         = "arn:aws:kms:eu-west-2:123456789012:key/EXAMPLE-KEY-ID"
region              = "eu-west-2"
