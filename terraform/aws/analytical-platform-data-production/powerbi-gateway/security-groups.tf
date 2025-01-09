module "security_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = local.name
  description = "PowerBI Gateway SG"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["10.0.0.0/16"]
  ingress_rules       = ["https-443-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = {
    Name = local.name
  }
}
