resource "aws_iam_role_policy_attachment" "alpha_vcms_crawler_policy" {
  role       = aws_iam_role.alpha_vcms_data_crawler.name
  policy_arn = aws_iam_policy.alpha_vcms_crawler_policy.arn
}

resource "aws_iam_role_policy_attachment" "aws_glue_service_role_policy" {
  role       = aws_iam_role.alpha_vcms_data_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueServiceRole"
}
