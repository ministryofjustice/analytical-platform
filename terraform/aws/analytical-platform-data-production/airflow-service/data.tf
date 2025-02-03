data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_iam_openid_connect_provider" "eks_oidc" {
  for_each = local.analytical_platform_compute_environments

  arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/${each.value.eks_oidc_id}"
}
