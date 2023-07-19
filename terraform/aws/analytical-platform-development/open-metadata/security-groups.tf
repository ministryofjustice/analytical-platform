module "rds_security_group" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name = "openmetadata-rds"

  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = module.vpc.vpc_cidr_block /* TODO: lock down to private subnets */
    },
  ]
}

module "opensearch_security_group" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name = "openmetadata-opensearch"

  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = module.vpc.vpc_cidr_block /* TODO: lock down to private subnets */
    },
  ]
}
