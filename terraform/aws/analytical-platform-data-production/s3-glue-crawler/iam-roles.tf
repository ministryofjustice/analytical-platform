data "aws_iam_policy_document" "glue_assume_policy" {
  statement {
    sid     = "AllowAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alpha_vcms_data_crawler" {
  name                = "alpha-vcms-data-crawler"
  assume_role_policy  = data.aws_iam_policy_document.glue_assume_policy.json
  managed_policy_arns = [
    aws_iam_policy.alpha_vcms_crawler_policy.arn,
    "arn:aws:iam::aws:policy/AWSGlueServiceRole"
  ]
}
