# Eventbridge rule to capture S3 GetObject API calls to the athena query bucket
# TO DO: Change to AE SSO account - currently DE SSO account for testing only
resource "aws_cloudwatch_event_rule" "ae_download_athena_csv" {
  name        = "capture-ae-athena-csv-download"
  description = "Captures Athena CSV downloads by the AE SSO role"

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["s3.amazonaws.com"],
      "eventName" : ["GetObject"],
      "requestParameters" : {
        "bucketName" : [{
          "wildcard" : "aws-athena-query-results-*"
        }],
        "key" : [{
          "suffix" : {
            "equals-ignore-case" : ".csv"
          }
        }]
      },
      "sourceIPAddress" : [{
        "anything-but" : ["athena.amazonaws.com"]
      }]
      "userIdentity" : {
        "type" : ["AssumedRole"],
        "sessionContext" : {
          "sessionIssuer" : {
            "userName" : ["AWSReservedSSO_mp-analytics-engineering_90d3c7659e13fe3b"]
          }
        }
      }
    }
  })

  tags = var.tags
}

# Creating SNS for distributing messages
resource "aws_sns_topic" "ae_download_athena_csv" {
  name = "ae-download-athena-csv-events"
  tags = var.tags
}

data "aws_iam_policy_document" "ae_download_athena_csv" {
  statement {
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.ae_download_athena_csv.arn]
  }
}

resource "aws_sns_topic_policy" "ae_download_athena_csv" {
  arn    = aws_sns_topic.ae_download_athena_csv.arn
  policy = data.aws_iam_policy_document.ae_download_athena_csv.json
}

# EventBridge target
resource "aws_cloudwatch_event_target" "ae_download_athena_csv" {
  rule      = aws_cloudwatch_event_rule.ae_download_athena_csv.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.ae_download_athena_csv.arn

  input_transformer {
    input_paths = {
      user   = "$.detail.userIdentity.principalId"
      time   = "$.detail.eventTime"
      bucket = "$.detail.requestParameters.bucketName"
      object = "$.detail.requestParameters.key"
    }
    input_template = <<EOF
    {
        "User": <user>,
        "Time": <time>,
        "Bucket": <bucket>,
        "Object": <object>
    }
    EOF
  }
}

# Create a resource to subscribe to SNS topic
# Slack notifications
resource "aws_sns_topic_subscription" "ae_download_athena_csv_slack" {
  topic_arn = aws_sns_topic.ae_download_athena_csv.arn
  protocol  = "https"
  endpoint  = data.aws_secretsmanager_secret_version.ae_download_athena_csv_secret_slack_webhook.secret_string
}
