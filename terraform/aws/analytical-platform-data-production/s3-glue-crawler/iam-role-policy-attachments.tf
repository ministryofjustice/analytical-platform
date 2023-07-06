resource "aws_iam_role_policy_attachment" "vcms_crawler_policy" {
  role       = aws_iam_role.glue_vcms_crawler_role.name
  policy_arn = aws_iam_policy.vcms_crawler_policy.arn
}

resource "aws_iam_role_policy_attachment" "aws_glue_service_role_policy" {
  role       = aws_iam_role.glue_vcms_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueServiceRole"
}
