resource "aws_iam_role_policy_attachment" "rds_s3_export" {
  role       = aws_iam_role.rds_s3_export.name
  policy_arn = aws_iam_policy.rds_s3_export.arn
}