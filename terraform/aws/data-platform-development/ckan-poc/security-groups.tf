##################################################
# CKAN ALB
##################################################

module "ckan_alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = "data-platform-development-ckan-alb"
  description = "Security group for CKAN ALB allowing traffic from MoJ Digital GlobalProtect VPN"
  vpc_id      = data.aws_vpc.mp_platforms_development.id

  ingress_cidr_blocks = ["35.176.93.186/32"] # https://github.com/ministryofjustice/moj-ip-addresses/blob/main/moj-cidr-addresses.yml#L289
  ingress_rules = [
    "http-80-tcp",
    "https-443-tcp"
  ]

  egress_with_source_security_group_id = [
    {
      from_port                = 5000
      to_port                  = 5000
      protocol                 = "tcp"
      description              = "CKAN"
      source_security_group_id = module.ckan_ec2_security_group.security_group_id
    }
  ]
}

##################################################
# CKAN EC2
##################################################

module "ckan_ec2_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = "data-platform-development-ckan-ec2"
  description = "Security group for CKAN EC2 allowing traffic from CKAN ALB"
  vpc_id      = data.aws_vpc.mp_platforms_development.id

  ingress_with_source_security_group_id = [
    {
      from_port                = 5000
      to_port                  = 5000
      protocol                 = "tcp"
      description              = "CKAN"
      source_security_group_id = module.ckan_alb_security_group.security_group_id
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = [
    "all-all"
  ]
}
