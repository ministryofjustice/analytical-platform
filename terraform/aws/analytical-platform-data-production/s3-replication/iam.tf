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
    resources = ["arn:aws:s3:::dsa-cdl-police-s3-deposit-cjs-npa/*"]
  }

  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
      "s3:PutInventoryConfiguration"
    ]
    resources = [module.alpha_mojap_ho_data_transfer_test.s3_bucket_arn]
  }

  statement {
    sid    = "SourceBucketObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:InitiateReplication",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]
    resources = ["${module.alpha_mojap_ho_data_transfer_test.s3_bucket_arn}/*"]
  }

  statement {
    sid    = "BatchReplicationManifestAndReportPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject"
    ]
    resources = [
      "${module.alpha_mojap_ho_data_transfer_test.s3_bucket_arn}/*",
      "arn:aws:s3:::dsa-cdl-police-s3-deposit-cjs-npa/*"
    ]
  }
}

resource "aws_iam_policy" "alpha_mojap_ho_data_transfer_replication" {
  name   = "alpha-mojap-ho-data-transfer-test-replication"
  policy = data.aws_iam_policy_document.alpha_mojap_ho_data_transfer_replication.json
}

data "aws_iam_policy_document" "alpha_mojap_ho_data_transfer_replication_trust" {
  statement {
    sid     = "TrustS3"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "s3.amazonaws.com",
        "batchoperations.s3.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "alpha_mojap_ho_data_transfer_replication" {
  name               = "alpha-mojap-ho-data-transfer-test-replication"
  assume_role_policy = data.aws_iam_policy_document.alpha_mojap_ho_data_transfer_replication_trust.json
}

resource "aws_iam_role_policy_attachment" "alpha_mojap_ho_data_transfer_replication" {
  role       = aws_iam_role.alpha_mojap_ho_data_transfer_replication.name
  policy_arn = aws_iam_policy.alpha_mojap_ho_data_transfer_replication.arn
}
