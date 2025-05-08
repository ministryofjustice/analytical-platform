module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name                   = local.name
  cidr                   = local.vpc_cidr
  azs                    = local.azs
  private_subnets        = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 2)]
  public_subnets         = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  enable_dns_hostnames   = true
  enable_dns_support     = true
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Name = local.name
  }
}

resource "aws_cloudwatch_log_group" "vpc" {
  name              = "data_production_powerbi_vpc_flow_logs"
  kms_key_id        = aws_kms_key.data_production_vpc_key.arn
  retention_in_days = 365
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

data "aws_iam_policy_document" "cloudwatch_kms_key_policy" {

  statement {
    sid    = "LogGroupKMSPermissions"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
    #checkov:skip=CKV_AWS_356:Constrained via resource policy
    #checkov:skip=CKV_AWS_111:Constrained via resource policy
    #checkov:skip=CKV_AWS_109:Constrained via resource policy
    resources = ["*"]
  }

  statement {
    sid     = "AllowKeyManagement"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type = "AWS"
      identifiers = concat(
        tolist(data.aws_iam_roles.analytical_platform_data_production_sso_administrator_access_roles.arns),
        ["arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/GlobalGitHubActionAdmin"]
      )
    }
    #checkov:skip=CKV_AWS_356:Constrained via resource policy
    #checkov:skip=CKV_AWS_111:Constrained via resource policy
    #checkov:skip=CKV_AWS_109:Constrained via resource policy
    resources = ["*"]
  }
}

resource "aws_kms_key" "data_production_vpc_key" {
  description             = "KMS Key for CloudWatch Logs Encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloudwatch_kms_key_policy.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_log" {
  name               = "vpc_flow_log"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "flow_log" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    #tfsec:ignore:avd-aws-0057:needs to access multiple resources
    #checkov:skip=CKV_AWS_356:Needs to access multiple resources
    #checkov:skip=CKV_AWS_111:Needs to access multiple resources
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flow_log" {
  name   = "vpc_flow_log"
  role   = aws_iam_role.flow_log.id
  policy = data.aws_iam_policy_document.flow_log.json
}
