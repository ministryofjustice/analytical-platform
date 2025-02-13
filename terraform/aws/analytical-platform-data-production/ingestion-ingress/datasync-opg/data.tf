data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_kms_alias" "kms" {
  for_each = toset(keys(local.analytical_platform_ingestion_environments))
  name     = "alias/s3/mojap-data-production-datasync-opg-ingress-${each.key}"
}
