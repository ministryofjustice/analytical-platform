resource "aws_iam_role" "migration_replication" {

  name = "${local.name}-parquet-exports-replication-${var.tags["environment"]}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = [
            "s3.amazonaws.com",
            "batchoperations.s3.amazonaws.com"
          ]
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

resource "aws_s3_bucket" "batch_manifest" {
  count = local.migration_replication_create ? 1 : 0

  bucket_prefix = "${local.name}-batch-manifest-${var.tags["environment"]}"

  tags = var.tags
}

resource "aws_iam_policy" "migration_replication" {

  name = "${local.name}-parquet-exports-replication-IAM-${var.tags["environment"]}-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "SourceBucketPermissions"
        Effect = "Allow"

        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:PutInventoryConfiguration"
        ]

        Resource = [
          module.rds_export.parquet_exports_bucket_arn
        ]
      },
      {
        Sid    = "SourceObjectPermissions"
        Effect = "Allow"

        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:InitiateReplication"
        ]

        Resource = [
          "${module.rds_export.parquet_exports_bucket_arn}/*"
        ]
      },
      {
        Sid    = "DestinationPermissions"
        Effect = "Allow"

        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]

        Resource = [
          "${local.batch_destination_bucket_arn}/*"
        ]
      },
      {
        Sid    = "ManifestAndReportPermissions"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]

        Resource = [
          "${aws_s3_bucket.batch_manifest.arn}/*"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "migration_replication" {

  role       = aws_iam_role.migration_replication.name
  policy_arn = aws_iam_policy.migration_replication.arn
}
