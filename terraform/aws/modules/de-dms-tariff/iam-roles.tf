data "aws_caller_identity" "current" {}

# IAM Role for DMS VPC Access
resource "aws_iam_role" "dms" {
  name = "${var.db}-dms-${var.environment}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "dms.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.db}-dms-${var.environment}"
  }
}

resource "aws_iam_role_policy" "dms" {
  name = "${var.db}-dms-${var.environment}"
  role = aws_iam_role.dms.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${var.landing_bucket}",
        "Sid" : "AllowListBucket"
      },
      {
        "Action" : [
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${var.landing_bucket}/${var.landing_bucket_folder}/*",
        "Sid" : "AllowDeleteAndPutObject"
      },
      {
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:secret:managed_pipelines/${var.environment}/slack_notifications*",
        "Sid" : "AllowGetSecretValue"
      }
    ]
  })
}
