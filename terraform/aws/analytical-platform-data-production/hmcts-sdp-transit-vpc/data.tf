data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret_version" "hmcts_cloudgateway_bgp_auth_key" {
  secret_id = "hmcts-cloudgateway-bgp-auth-key"
}

data "aws_vpc" "airflow_dev" {
  provider = aws.analytical-platform-data-production-eu-west-1

  id = "vpc-0a6cb83c3c614dcba"
}

data "aws_vpn_gateway" "airflow_dev" {
  provider = aws.analytical-platform-data-production-eu-west-1

  id = "vgw-02f10f1bacf2dd3fa"
}

data "aws_vpc" "airflow_prod" {
  provider = aws.analytical-platform-data-production-eu-west-1

  id = "vpc-047b97f77da3ab143"
}

data "aws_vpn_gateway" "airflow_prod" {
  provider = aws.analytical-platform-data-production-eu-west-1

  id = "vgw-099d9b2d0d3576880"
}
