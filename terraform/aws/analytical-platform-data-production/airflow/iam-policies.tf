data "aws_iam_policy_document" "airflow_analytical_platform_development" {
  statement {
    sid       = "AllowS3"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

module "airflow_analytical_platform_development_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.28.0"

  name = "airflow-analytical-platform-development"

  policy = data.aws_iam_policy_document.airflow_analytical_platform_development.json
}

data "aws_iam_policy_document" "airflow_dev_execution_role_policy" {
  statement {
    sid       = ""
    effect    = "Allow"
    actions   = ["airflow:PublishMetrics"]
    resources = ["arn:aws:airflow:eu-west-1:593291632749:environment/dev"]
  }

  statement {
    sid       = ""
    effect    = "Deny"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["s3:List*", "s3:GetObject*", "s3:GetBucket*"]
    resources = [
      "arn:aws:s3:::mojap-airflow-dev/*",
      "arn:aws:s3:::mojap-airflow-dev"
    ]
  }
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:GetQueryResults",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetLogEvents",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    resources = ["arn:aws:logs:eu-west-1:593291632749:log-group:airflow-dev-*"]
  }
  statement {
    sid       = ""
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility"
    ]
    resources = ["arn:aws:sqs:eu-west-1:*:airflow-celery-*"]
  }
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt"
    ]
    not_resources = ["arn:aws:kms:*:593291632749:key/*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["sqs.eu-west-1.amazonaws.com"]
    }
  }
  statement {
    sid       = ""
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:aws:eks:eu-west-1:593291632749:cluster/airflow-dev"]
  }
}

data "aws_iam_policy_document" "airflow_dev_execution_assume_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "airflow.amazonaws.com",
        "airflow-env.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "airflow_dev_cloudwatch_logs_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
  }
}
data "aws_iam_policy_document" "airflow_dev_cloudwatch_logs_assume_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "vpc-flow-logs.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["593291632749"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ec2:eu-west-1:593291632749:vpc-flow-log/*"]
    }
  }
}
