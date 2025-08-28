data "aws_iam_policy_document" "coat_datasync_iam_policy" {
  statement {
    sid    = "coat-datasync-dms-permissions"
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
    sid    = "coat-datasync-s3-bucket-permissions"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]
    resources = [
      "arn:aws:s3:::<DESTINATION_BUCKET_NAME>"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [data.aws_caller_identity.session.account_id]
    }
  }

  statement {
    sid    = "coat-datasync-s3-object-permissions"
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
      "arn:aws:s3:::<DESTINATION_BUCKET_NAME>/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = ["123456789012"]
    }
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
