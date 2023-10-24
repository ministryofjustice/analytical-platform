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
    sid    = "AllowAWSCloudWatch"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = ["*"]
  }
  statement {
    sid    = "AllowAWSEvents"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = ["*"]
  }
}

resource "aws_kms_key" "guardduty_findings" {
  provider = aws.target

  description         = "GuardDuty Findings"
  enable_key_rotation = true
}

resource "aws_kms_alias" "guardduty_findings" {
  name          = "alias/guardduty-findings"
  target_key_id = aws_kms_key.guardduty_findings.key_id
  provider      = aws.target
}

resource "aws_kms_key_policy" "guardduty_findings" {
  provider = aws.target

  key_id = aws_kms_key.guardduty_findings.key_id
  policy = data.aws_iam_policy_document.kms_key.json
}

resource "aws_sns_topic" "guardduty_findings" {
  provider = aws.target

  name              = "guardduty-findings"
  kms_master_key_id = aws_kms_key.guardduty_findings.key_id
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
      identifiers = ["*"]
    }
    resources = [aws_sns_topic.guardduty_findings.arn]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.target.account_id]
    }
  }
  statement {
    sid     = "AllowAWSEvents"
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [aws_sns_topic.guardduty_findings.arn]
  }
}

resource "aws_sns_topic_policy" "guardduty_findings" {
  provider = aws.target

  arn    = aws_sns_topic.guardduty_findings.arn
  policy = data.aws_iam_policy_document.sns_topic.json
}

resource "aws_sns_topic_subscription" "pagerduty" {
  provider = aws.target

  topic_arn              = aws_sns_topic.guardduty_findings.arn
  protocol               = "https"
  endpoint               = local.pagerduty_alerting_endpoint
  endpoint_auto_confirms = true
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  provider = aws.target

  name        = "guardduty-findings"
  description = "GuardDuty Findings"

  event_pattern = jsonencode({
    "source" : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"],
    "severity" : [
      4,
      4.0,
      4.1,
      4.2,
      4.3,
      4.4,
      4.5,
      4.6,
      4.7,
      4.8,
      4.9,
      5,
      5.0,
      5.1,
      5.2,
      5.3,
      5.4,
      5.5,
      5.6,
      5.7,
      5.8,
      5.9,
      6,
      6.0,
      6.1,
      6.2,
      6.3,
      6.4,
      6.5,
      6.6,
      6.7,
      6.8,
      6.9,
      7,
      7.0,
      7.1,
      7.2,
      7.3,
      7.4,
      7.5,
      7.6,
      7.7,
      7.8,
      7.9,
      8,
      8.0,
      8.1,
      8.2,
      8.3,
      8.4,
      8.5,
      8.6,
      8.7,
      8.8,
      8.9
    ]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_findings_sns" {
  provider = aws.target

  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyFindingsToSNS"
  arn       = aws_sns_topic.guardduty_findings.arn
}
