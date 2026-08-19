#IAM role for Airflow to access the Splink S3 bucket
resource "aws_iam_role" "airflow_splink_test" {
  name = "airflow-${local.application_name}-splink-test"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowECSTaskAssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.test_tags, {
    Name = "iam-role-airflow-${local.application_name}-splink-test"
  })
}

#IAM policy for Airflow to access the Splink S3 bucket
resource "aws_iam_policy" "airflow_splink_test_s3_access" {
  name        = "airflow-${local.application_name}-splink-test-s3-access"
  description = "S3 access for airflow splink test (List/Get/Put)"
  policy      = data.aws_iam_policy_document.airflow_splink_test_s3_access.json

  tags = merge(local.test_tags, {
    Name = "iam-policy-airflow-${local.application_name}-splink-test-s3-access"
  })
}

#IAM policy attachement for Airflow to access the Splink S3 bucket
resource "aws_iam_role_policy_attachment" "airflow_splink_test_s3_access" {
  role       = aws_iam_role.airflow_splink_test.name
  policy_arn = aws_iam_policy.airflow_splink_test_s3_access.arn
}

#IAM policy for SNS topic
data "aws_iam_policy_document" "splink_bucket_alerting_topic_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.splink_bucket_alerting_topic.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_cloudwatch_event_rule.s3_bucket_splink_event_rule.arn
      ]
    }
  }

  statement {
    sid    = "AllowCloudTrailPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["sns:Publish"]

    resources = [
      aws_sns_topic.splink_bucket_alerting_topic.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_cloudtrail.splink_s3_trail.arn
      ]
    }
  }
}

# Add policy for Airflow python script to access the bucket
data "aws_iam_policy_document" "airflow_splink_test_s3_access" {
  statement {
    sid    = "ListSplinkTestBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      module.s3_bucket_splink_test.s3_bucket_arn
    ]
  }

  statement {
    sid    = "ReadWriteSplinkTestObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${module.s3_bucket_splink_test.s3_bucket_arn}/*"
    ]
  }
}