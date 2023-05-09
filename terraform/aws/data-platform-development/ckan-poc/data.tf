##################################################
# Modernisation Platform VPC
##################################################

data "aws_vpc" "mp_platforms_development" {
  filter {
    name   = "tag:Name"
    values = ["platforms-development"]
  }
}

##################################################
# Modernisation Platform Subnets
##################################################

data "aws_subnets" "mp_platforms_development_general_data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.mp_platforms_development.id]
  }
  filter {
    name   = "tag:Name"
    values = ["platforms-development-general-data-*"]
  }
}

data "aws_subnets" "mp_platforms_development_general_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.mp_platforms_development.id]
  }
  filter {
    name   = "tag:Name"
    values = ["platforms-development-general-private-*"]
  }
}

data "aws_subnets" "mp_platforms_development_general_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.mp_platforms_development.id]
  }
  filter {
    name   = "tag:Name"
    values = ["platforms-development-general-public-*"]
  }
}

##################################################
# CKAN ALB IPs
# This is a workaround as we're not able to use
# CNAMEs at the apex of a domain.
##################################################

data "dns_a_record_set" "ckan_alb" {
  host = module.ckan_alb.lb_dns_name
}
