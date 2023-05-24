data "aws_availability_zones" "available" {
  provider = aws.data-engineering
}

locals {
  name = "data-engineering-app-vpc"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 1)

  tags = {
    Name = local.name
    repo = "github.com/ministryofjustice/data-platform/tree/main/terraform/data-engineering"
  }

  ami_id = "ami-0256f8c0fabe51702" # can't pass ignore_changes to module, so must statically code
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  providers = {
    aws = aws.data-engineering
  }
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0.0"

  name = local.name
  cidr = local.vpc_cidr

  azs                  = local.azs
  private_subnets      = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets       = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 1)]
  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = local.tags
}

################################################################################
# Additional Resources
################################################################################

module "security_group" {
  providers = {
    aws = aws.data-engineering
  }
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = local.name
  description = "Data Engineering App SG"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

################################################################################
# EC2
################################################################################

module "ec2" {
  providers = {
    aws = aws.data-engineering
  }
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = local.name

  ami                         = local.ami_id
  instance_type               = "t3.medium"
  availability_zone           = local.azs[0]
  subnet_id                   = element(module.vpc.private_subnets, 0)
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = false
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 8
    },
  ]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = 10
      encrypted   = true
    }
  ]

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    SSMCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  tags = local.tags
}
