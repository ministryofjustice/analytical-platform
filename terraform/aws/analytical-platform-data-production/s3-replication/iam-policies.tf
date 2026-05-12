data "aws_iam_policy_document" "replication" {
  for_each = local.enabled_replication_configurations

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
    resources = ["${each.value.destination_bucket_arn}/*"]
  }

  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
      "s3:PutInventoryConfiguration"
    ]
    resources = ["${each.value.source_bucket_arn}"]
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
    resources = ["${each.value.source_bucket_arn}/*"]
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
      "${each.value.source_bucket_arn}/*",
      "${each.value.destination_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "replication" {
  for_each = local.enabled_replication_configurations

  name   = "${each.value.source_bucket_name}-replication"
  policy = data.aws_iam_policy_document.replication[each.key].json
}

data "aws_iam_policy_document" "replication_trust" {
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
