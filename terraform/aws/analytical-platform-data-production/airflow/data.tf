##################################################
# AWS
##################################################

# Calling session
data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_eks_cluster" "analytical_platform_development" {
  provider = aws.analytical-platform-development

  name = "development-aWrhyc0m"
}

data "tls_certificate" "analytical_platform_development_eks_oidc_issuer" {
  url = data.aws_eks_cluster.analytical_platform_development.identity[0].oidc[0].issuer
}
