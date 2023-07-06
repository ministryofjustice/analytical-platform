resource "aws_iam_role_policy_attachment" "vcms_crawler_policy" {
  for_each = toset([
    aws_iam_policy.vcms-crawler-policy.arn,
    "arn:aws:iam::aws:policy/AWSGlueServiceRole"
  ])

  role       = aws_iam_role.AWSGlueServiceRole_vcms_crawler.name
  policy_arn = each.value
}