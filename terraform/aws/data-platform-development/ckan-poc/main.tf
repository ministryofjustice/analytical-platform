##################################################
# Route53
##################################################

resource "aws_route53_zone" "ckan_development_data_platform_service_justice_gov_uk" {
  name = "ckan.development.data-platform.service.justice.gov.uk"
}

##################################################
# Security Group
##################################################

module "ckan_ec2_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = "data-platform-development-ckan"
  description = "Security group for CKAN instance allowing traffic from MoJ Digital GlobalProtect VPN and to the internet"
  vpc_id      = data.aws_vpc.mp_platforms_development.id

  ingress_cidr_blocks = ["35.176.93.186/32"] # https://github.com/ministryofjustice/moj-ip-addresses/blob/main/moj-cidr-addresses.yml#L289
  ingress_rules = [
    "http-80-tcp",
    "https-443-tcp"
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = [
    "all-all"
  ]
}

##################################################
# EC2 Instance
##################################################

module "ckan_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.0.0"

  name = "data-platform-development-ckan"

  ami_ssm_parameter = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type     = "t3.large"
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 150
    }
  ]
  user_data_base64            = base64encode(file("${path.module}/src/user-data.sh"))
  user_data_replace_on_change = true

  subnet_id                   = data.aws_subnets.mp_platforms_development_general_public.ids[0]
  vpc_security_group_ids      = [module.ckan_ec2_security_group.security_group_id]
  associate_public_ip_address = true

  create_iam_instance_profile = true
  iam_role_name               = "data-platform-development-ckan"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}
