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
  name               = "alpha-vcms-data-crawler"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "alpha_vcms_data_crawler_service_policy" {
  role       = aws_iam_role.alpha_vcms_data_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "alpha_vcms_data_crawler_vcms_policy" {
  role       = aws_iam_role.alpha_vcms_data_crawler.name
  policy_arn = aws_iam_policy.alpha_vcms_data_crawler.arn
}
