# -----------------------------------------------------------------------------
# Security Group for Redshift Serverless
# -----------------------------------------------------------------------------
data "aws_prefix_list" "s3" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.eu-west-2.s3"]
  }
}

module "redshift_sg" {
  # checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  vpc_id      = var.vpc_id
  name        = "${var.project_name}-${var.environment}-redshift"
  description = "Control access to and from Redshift Serverless"

  ingress_with_self = [{ rule = "all-all" }]
  egress_with_self  = [{ rule = "all-all" }]

  # Allow inbound from VPC CIDR for Redshift connections
  ingress_with_cidr_blocks = [
    {
      rule        = "redshift-tcp"
      cidr_blocks = var.vpc_cidr
      description = "Redshift from VPC"
    },
  ]

  # Allow outbound HTTPS for Secrets Manager access
  egress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = var.vpc_cidr
      description = "Redshift to Secrets Manager"
    },
  ]

  tags = var.tags
}

# Allow outbound to S3 via prefix list
resource "aws_vpc_security_group_egress_rule" "redshift_to_s3" {
  security_group_id = module.redshift_sg.security_group_id
  to_port           = 443
  from_port         = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.s3.id
  description       = "Redshift to S3"
}
