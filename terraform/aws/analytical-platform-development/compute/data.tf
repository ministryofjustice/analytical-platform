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

data "aws_iam_roles" "eks_sso_access_role" {
  name_regex  = "AWSReservedSSO_${local.eks_sso_access_role}_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
