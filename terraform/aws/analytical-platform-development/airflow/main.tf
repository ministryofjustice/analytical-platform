module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name            = "airflow-development"
  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  cidr            = "10.27.128.0/23"
  private_subnets = ["10.27.128.0/26", "10.27.128.64/26", "10.27.128.128/26"]
  public_subnets  = ["10.27.129.0/26", "10.27.129.64/26", "10.27.129.128/26"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_flow_log                           = true
  create_flow_log_cloudwatch_log_group      = true
  create_flow_log_cloudwatch_iam_role       = true
  flow_log_cloudwatch_log_group_name_suffix = "airflow-development"
}

module "smtp_vpc_endpoint_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "airflow-development-smtp-vpc-endpoint"
  description = "SMTP VPC Endpoint"

  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
  ingress_rules       = ["smtp-submission-587-tcp"]
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "4.0.2"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    email-smtp = {
      service             = "email-smtp"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [module.smtp_vpc_endpoint_security_group.security_group_id]
      private_dns_enabled = true
      tags                = { Name = "airflow-development-smtp" }
    }
  }
}

module "airflow_s3_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix = "moj-data-platform-airflow"

  tags = {}
}

resource "aws_s3_object" "airflow_requirements" {
  bucket      = module.airflow_s3_bucket.bucket.id
  source      = "${path.module}/src/requirements.txt"
  key         = "requirements.txt"
  source_hash = filemd5("${path.module}/src/requirements.txt")
}

module "airflow_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.0.0"

  name   = "airflow-development"
  vpc_id = module.vpc.vpc_id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]
}

data "aws_iam_policy_document" "airflow_execution_policy" {
  statement {
    sid       = "AllowAirflowPublishMetrics"
    effect    = "Allow"
    actions   = ["airflow:PublishMetrics"]
    resources = ["arn:aws:airflow:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:environment/development"]
  }
  statement {
    sid       = "DenyS3ListAllMyBuckets"
    effect    = "Deny"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
  statement {
    sid    = "AllowS3GetListBucketObjects"
    effect = "Allow"
    actions = [
      "s3:GetBucket*",
      "s3:GetObject*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::${module.airflow_s3_bucket.bucket.id}",
      "arn:aws:s3:::${module.airflow_s3_bucket.bucket.id}/*"
    ]
  }
  statement {
    sid    = "AllowCloudWatchLogsCreatePutGet"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:airflow-development-*"]
  }
  statement {
    sid       = "AllowCloudWatchLogGroupsDescribe"
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }
  statement {
    sid       = "AllowS3GetAccountPublicAccessBlock"
    effect    = "Allow"
    actions   = ["s3:GetAccountPublicAccessBlock"]
    resources = ["*"]
  }
  statement {
    sid       = "AllowCloudWatchPutMetricData"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
  statement {
    sid    = "AllowSQSChangeDeleteGetReceiveSend"
    effect = "Allow"
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:*:airflow-celery-*"]
  }
}

module "airflow_execution_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.20.0"

  name   = "airflow-development-execution-policy"
  policy = data.aws_iam_policy_document.airflow_execution_policy.json
}

module "airflow_execution_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.20.0"

  create_role       = true
  role_name         = "airflow-development-execution-role"
  role_requires_mfa = false

  trusted_role_services = [
    "airflow.amazonaws.com",
    "airflow-env.amazonaws.com"
  ]

  custom_role_policy_arns = [module.airflow_execution_policy.arn]
}

resource "aws_mwaa_environment" "main" {
  name                            = "development"
  airflow_version                 = "2.4.3"
  environment_class               = "mw1.small"
  weekly_maintenance_window_start = "SAT:00:00"

  execution_role_arn = module.airflow_execution_role.iam_role_arn

  source_bucket_arn    = module.airflow_s3_bucket.bucket.arn
  dag_s3_path          = "dags/"
  requirements_s3_path = "requirements.txt"

  max_workers = 2
  min_workers = 1
  schedulers  = 2

  webserver_access_mode = "PUBLIC_ONLY"

  network_configuration {
    security_group_ids = [module.airflow_security_group.security_group_id]
    subnet_ids         = slice(module.vpc.private_subnets, 0, 2)
  }
}
