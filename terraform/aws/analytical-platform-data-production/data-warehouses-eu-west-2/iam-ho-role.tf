data "aws_iam_policy_document" "alpha_mojap_ho_data_transfer_replication" {
  statement {
    sid    = "DestinationBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = ["arn:aws:s3:::destination-bucket/*"]
  }

  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [module.alpha-mojap-ho-data-transfer-test.s3_bucket_arn]
  }

  statement {
    sid    = "SourceBucketObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${module.alpha-mojap-ho-data-transfer-test.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "alpha_mojap_ho_data_transfer_replication" {
  count = var.alpha_mojap_ho_data_transfer_replication_enabled ? 1 : 0

  name   = "alpha-mojap-ho-data-transfer-test-replication"
  policy = data.aws_iam_policy_document.alpha_mojap_ho_data_transfer_replication.json
}

data "aws_iam_policy_document" "alpha_mojap_ho_data_transfer_replication_trust" {
  statement {
    sid     = "TrustS3"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alpha_mojap_ho_data_transfer_replication" {
  count = var.alpha_mojap_ho_data_transfer_replication_enabled ? 1 : 0

  name               = "alpha-mojap-ho-data-transfer-test-replication"
  assume_role_policy = data.aws_iam_policy_document.alpha_mojap_ho_data_transfer_replication_trust.json
}

resource "aws_iam_role_policy_attachment" "alpha_mojap_ho_data_transfer_replication" {
  count = var.alpha_mojap_ho_data_transfer_replication_enabled ? 1 : 0

  role       = aws_iam_role.alpha_mojap_ho_data_transfer_replication[0].name
  policy_arn = aws_iam_policy.alpha_mojap_ho_data_transfer_replication[0].arn
}

