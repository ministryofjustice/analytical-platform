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

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_route53_zone" "main" {
  name         = var.route53_zone
  private_zone = false
}

data "aws_iam_roles" "aws_sso_administrator_access" {
  name_regex  = "AWSReservedSSO_${var.aws_sso_role_prefix}_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
