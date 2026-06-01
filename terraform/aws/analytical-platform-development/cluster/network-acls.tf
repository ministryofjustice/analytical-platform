##################################################
# Network ACL
##################################################

module "network_acl" {
  source  = "terraform-aws-modules/network-acls/aws"
  version = "1.0.0"

  name   = "${var.environment}-vpc-nacl"
  vpc_id = module.vpc.vpc_id

  ingress_rules = concat(
    [
      {
        rule_number = 100
        action      = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = var.vpc_cidr
      }
    ],
    [
      for index, cidr in var.moj_vpn_cidrs : {
        rule_number = 200 + index
        action      = "allow"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_block  = cidr
      }
    ]
  )

  egress_rules = [
    {
      rule_number = 100
      action      = "allow"
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  subnet_ids = concat(
    module.vpc.private_subnets,
    module.vpc.public_subnets,
    module.vpc.database_subnets
  )

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-vpc-nacl"
    }
  )
}