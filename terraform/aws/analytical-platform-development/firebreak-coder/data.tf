data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "data_platform_moj_woffenden_dev" {
  name = "data-platform.moj.woffenden.dev"
}

data "aws_vpcs" "open_metadata" {
  tags = {
    Name = "open-metadata"
  }
}

data "aws_vpc" "open_metadata" {
  id = data.aws_vpcs.open_metadata.ids[0]
}

data "aws_eks_cluster" "open_metadata" {
  name = "open-metadata"
}

data "aws_secretsmanager_secret_version" "coder_azuread_client_id" {
  secret_id = "coder/azuread/client-id"
}

data "aws_secretsmanager_secret_version" "coder_azuread_client_secret" {
  secret_id = "coder/azuread/client-secret"
}

data "aws_secretsmanager_secret_version" "coder_azuread_issuer_url" {
  secret_id = "coder/azuread/issuer-url"
}

data "kubernetes_service_account" "coder" {
  metadata {
    name      = "coder"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
}
