data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "dns_a_record_set" "apc_ingress_prod" {
  host = "ingress.compute.analytical-platform.service.justice.gov.uk"
}
