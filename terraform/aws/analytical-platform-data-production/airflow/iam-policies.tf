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
  version = "5.30.0"

  name = "airflow-analytical-platform-development"

  policy = data.aws_iam_policy_document.airflow_analytical_platform_development.json
}

data "aws_iam_policy_document" "airflow_dev_execution_role_policy" {
  statement {
    sid       = ""
    effect    = "Allow"
    actions   = ["airflow:PublishMetrics"]
    resources = ["arn:aws:airflow:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:environment/dev"]
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
    resources = ["arn:aws:logs:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:log-group:airflow-dev-*"]
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
    not_resources = ["arn:aws:kms:*:${var.account_ids["analytical-platform-data-production"]}:key/*"]
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
    resources = ["arn:aws:eks:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:cluster/airflow-dev"]
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

data "aws_iam_policy_document" "airflow_dev_cluster_autoscaler_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "ec2:DescribeInstanceTypes",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeAutoScalingGroups"
    ]
    resources = ["*"]
  }

}

data "aws_iam_policy_document" "airflow_dev_cluster_autoscaler_assume_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/airflow-dev-node-instance-role"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "airflow_dev_flow_log_role_policy" {
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

data "aws_iam_policy_document" "airflow_dev_flow_log_assume_policy" {
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
      values   = [var.account_ids["analytical-platform-data-production"]]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ec2:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:vpc-flow-log/*"]
    }
  }

}

data "aws_iam_policy_document" "airflow_dev_node_instance_inline_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    resources = [
      "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/airflow-dev-cluster-autoscaler-role",
      "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/airflow*"
    ]
    actions = ["sts:AssumeRole"]
  }

}

data "aws_iam_policy_document" "airflow_dev_node_instance_assume_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",

      ]
    }
    actions = ["sts:AssumeRole"]
  }

}

data "aws_iam_policy_document" "airflow_dev_default_pod_assume_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/airflow-dev-node-instance-role"
      ]
    }
    actions = ["sts:AssumeRole"]
  }

}

data "aws_iam_policy_document" "airflow_dev_eks_assume_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com",

      ]
    }
    actions = ["sts:AssumeRole"]
  }

}

############################ AIRFLOW PRODUCTION INFRASTRUCTURE

data "aws_iam_policy_document" "airflow_prod_execution_assume_role_policy" {
  statement {
    # sid = ""
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["airflow.amazonaws.com", "airflow-env.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "airflow_prod_execution_role_policy" {
  statement {
    sid       = ""
    effect    = "Allow"
    actions   = ["airflow:PublishMetrics"]
    resources = ["arn:aws:airflow:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:environment/prod"]
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
      "arn:aws:s3:::mojap-airflow-prod/*",
      "arn:aws:s3:::mojap-airflow-prod"
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
    resources = ["arn:aws:logs:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:log-group:airflow-prod-*"]
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
    not_resources = ["arn:aws:kms:*:${var.account_ids["analytical-platform-data-production"]}:key/*"]
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
    resources = ["arn:aws:eks:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:cluster/airflow-prod"]
  }
}

data "aws_iam_policy_document" "airflow_prod_node_instance_assume_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",

      ]
    }
    actions = ["sts:AssumeRole"]
  }

}


data "aws_iam_policy_document" "airflow_prod_flow_log_role_policy" {
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

data "aws_iam_policy_document" "airflow_prod_flow_log_assume_policy" {
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
      values   = [var.account_ids["analytical-platform-data-production"]]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ec2:eu-west-1:${var.account_ids["analytical-platform-data-production"]}:vpc-flow-log/*"]
    }
  }
}

data "aws_iam_policy_document" "airflow_prod_node_instance_inline_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    resources = [
      "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/airflow-prod-cluster-autoscaler-role",
      "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/airflow*"
    ]
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "airflow_prod_eks_assume_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com",

      ]
    }
    actions = ["sts:AssumeRole"]
  }

}