data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "replication" {
  name               = "tf-iam-role-replication-${local.name}-${local.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [module.ppud_dev.s3_bucket_arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${module.ppud_dev.s3_bucket_arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["${module.ppud_dev.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {
  name   = "tf-iam-role-policy-replication-${local.name}-${local.env}"
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  region = "${data.aws_region.current.id}"

  role   = aws_iam_role.replication.arn
  bucket = module.ppud_dev.s3_bucket_id

  rule {
    id = "replication"

    status = "Enabled"

    destination {
      bucket        = module.rds_export.backup_uploads_s3_bucket_arn
      storage_class = "STANDARD"
    }
  }
}
