data "aws_iam_policy_document" "glue_policy" {
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

resource "aws_iam_role" "glue_vcms_crawler_role" {
  name               = "AWSGlueServiceRole-vcms-crawler"
  assume_role_policy = data.aws_iam_policy_document.glue_policy.json
}
