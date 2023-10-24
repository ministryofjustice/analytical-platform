data "aws_iam_policy_document" "kms_key" {
  statement {
    sid     = "EnableIAMUserPermissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.target.account_id}:root"]
    }
    resources = ["*"]
  }
  statement {
    sid    = "AllowAWSCostAlerts"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    principals {
      type        = "Service"
      identifiers = ["costalerts.amazonaws.com"]
    }
    resources = ["*"]
  }
}

resource "aws_kms_key" "ce_anomaly_monitor" {
  provider = aws.target

  description         = "Cost Explorer Anomaly Monitor"
  enable_key_rotation = true
}

resource "aws_kms_alias" "ce_anomaly_monitor" {
  provider      = aws.target

  name          = "alias/cost-explorer-anomaly-monitor"
  target_key_id = aws_kms_key.ce_anomaly_monitor.key_id
}

resource "aws_kms_key_policy" "ce_anomaly_monitor" {
  provider = aws.target

  key_id = aws_kms_key.ce_anomaly_monitor.key_id
  policy = data.aws_iam_policy_document.kms_key.json
}

resource "aws_sns_topic" "ce_anomaly_monitor" {
  provider = aws.target

  name              = "cost-explorer-anomaly-monitor"
  kms_master_key_id = aws_kms_key.ce_anomaly_monitor.key_id
}

data "aws_iam_policy_document" "sns_topic" {
  statement {
    sid    = "__default_statement_ID"
    effect = "Allow"
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.target.account_id}:root"]
    }
    resources = [aws_sns_topic.ce_anomaly_monitor.arn]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.target.account_id]
    }
  }
  statement {
    sid     = "AllowAWSCostAlerts"
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["costalerts.amazonaws.com"]
    }
    resources = [aws_sns_topic.ce_anomaly_monitor.arn]
  }
}

resource "aws_sns_topic_policy" "ce_anomaly_monitor" {
  provider = aws.target

  arn    = aws_sns_topic.ce_anomaly_monitor.arn
  policy = data.aws_iam_policy_document.sns_topic.json
}

resource "aws_sns_topic_subscription" "pagerduty" {
  provider = aws.target

  topic_arn              = aws_sns_topic.ce_anomaly_monitor.arn
  protocol               = "https"
  endpoint               = local.pagerduty_alerting_endpoint
  endpoint_auto_confirms = true
}

resource "aws_ce_anomaly_monitor" "service_monitor" {
  provider = aws.target

  name              = "aws-services"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "ce_anomaly_monitor_sns" {
  provider = aws.target

  name      = "SNS Subscription"
  frequency = "IMMEDIATE"

  threshold_expression {
    dimension {
      key           = var.ce_anomaly_subscription_threshold_expression_dimension
      values        = [var.ce_anomaly_subscription_threshold_expression_value]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  monitor_arn_list = [aws_ce_anomaly_monitor.service_monitor.arn]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.ce_anomaly_monitor.arn
  }
}
