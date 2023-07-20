module "rds_security_group" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV2_AWS_5:PoC only

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name = "coder-rds-postgres"

  vpc_id = data.aws_vpc.open_metadata.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.open_metadata.cidr_block /* TODO: lock down to private subnets */
    },
  ]
}
