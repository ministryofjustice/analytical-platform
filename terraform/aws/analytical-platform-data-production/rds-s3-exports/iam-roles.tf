data "aws_iam_policy_document" "export_role" {
  statement {
    sid     = "AllowAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["export.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_s3_export" {
  name               = "rds-s3-export"
  assume_role_policy = data.aws_iam_policy_document.export_role.json
}
