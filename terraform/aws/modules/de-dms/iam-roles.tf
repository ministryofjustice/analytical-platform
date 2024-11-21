# IAM Role for DMS VPC Access
resource "aws_iam_role" "dms" {
  name = "dms-${var.environment}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "dms.${data.aws_region.current.name}.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_policy_attachment" {
  role       = aws_iam_role.dms.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

data "aws_iam_policy_document" "dms_s3" {
  statement {
    sid       = "AllowListBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.landing_bucket}"]
  }

  statement {
    sid = "AllowDeleteAndPutObject"
    actions = [
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging"
    ]
    resources = ["arn:aws:s3:::${var.landing_bucket}/${var.landing_bucket_folder}/*"]
  }
}
