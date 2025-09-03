data "aws_iam_policy_document" "coat_datasync_iam_policy" {
  statement {
    sid    = "CoatDatasyncDmsPermissions"
    effect = "Allow"
    actions = [
      "dms:DescribeEndpoints",
      "dms:DescribeReplicationInstances",
      "dms:DescribeReplicationTasks",
      "dms:StartReplicationTask",
      "dms:StopReplicationTask",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CoatDatasyncS3BucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]
    resources = [
      "arn:aws:s3:::mojap-data-production-coat-cur-reports-v2-hourly" #TODO: Update call
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = ["593291632749"] #TODO: Update call
    }
  }

  statement {
    sid    = "CoatDatasyncS3ObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = [
      "arn:aws:s3:::mojap-data-production-coat-cur-reports-v2-hourly/*" #TODO: Update call
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = ["593291632749"] #TODO: Update
    }
  }

  statement {
    sid    = "SourceKeyPermissions"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
    ]
    resources = [
      module.coat_kms.key_arn
    ]
  }

  statement {
    sid    = "DestinationKeyPermissions"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      "arn:aws:kms:eu-west-1:593291632749:key/*" #TODO: Update call
    ]
  }

  statement {
    sid    = "CloudWatchLogsPermissions"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup"
    ]
    resources = [
      "${module.datasync_events_log_group.cloudwatch_log_group_arn}",
      "${module.datasync_events_log_group.cloudwatch_log_group_arn}:*",
      "${module.datasync_events_log_group.cloudwatch_log_group_arn}/*"
    ]
  }
}

module "coat_datasync_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.1"

  name_prefix = "coat-datasync-iam-policy"

  policy = data.aws_iam_policy_document.coat_datasync_iam_policy.json
}
