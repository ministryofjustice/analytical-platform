# Eventbridge rule to capture S3 GetObject API calls to the athena query bucket
# With DE account to test first
resource "aws_cloudwatch_event_rule" "ae-download-athena-csv" {
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
      "userIdentity" : {
        "type" : ["AssumedRole"],
        "invokedBy" : ["athena.amazonaws.com"],
        "sessionContext" : {
          "sessionIssuer" : {
            "userName" : ["AWSReservedSSO_modernisation-platform-data-eng_89c7a4cbe024b69a"]
          }
        }
      }
    }
  })
}

# Creating SNS for distributing messages
resource "aws_sns_topic" "ae-download-athena-csv" {
  name = "ae-download-athena-csv-events"
}

data "aws_iam_policy_document" "ae-download-athena-csv" {
  statement {
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.ae-download-athena-csv.arn]
  }
}

resource "aws_sns_topic_policy" "ae-download-athena-csv" {
  arn    = aws_sns_topic.ae-download-athena-csv.arn
  policy = data.aws_iam_policy_document.ae-download-athena-csv.json
}

# EventBridge target
resource "aws_cloudwatch_event_target" "ae-download-athena-csv" {
  rule      = aws_cloudwatch_event_rule.ae-download-athena-csv.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.ae-download-athena-csv.arn

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
# Using dev webhook currently
resource "aws_sns_topic_subscription" "ae-download-athena-csv" {
  topic_arn = aws_sns_topic.ae-download-athena-csv.arn
  protocol  = "https"
  endpoint  = data.aws_secretsmanager_secret_version.slack_webhook.secret_string
}
