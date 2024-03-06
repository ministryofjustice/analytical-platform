##################################################
# AWS
##################################################

data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_route53_zone" "analytical_platform_service_justice_gov_uk" {
  provider = aws.analytical-platform-production

  name = "analytical-platform.service.justice.gov.uk"
}
