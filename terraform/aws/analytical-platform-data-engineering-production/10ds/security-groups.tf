module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = local.name
  description = "Data Engineering App SG"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = {
    Name = local.name
  }
}
