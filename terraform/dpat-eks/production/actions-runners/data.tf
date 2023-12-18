data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret" "dpat_eks_production_account" {
  provider = aws.analytical-platform-management-production

  name = "dpat-eks/production/account"
}

data "aws_secretsmanager_secret_version" "dpat_eks_production_account" {
  provider = aws.analytical-platform-management-production

  secret_id = data.aws_secretsmanager_secret.dpat_eks_production_account.id
}

data "aws_secretsmanager_secret" "dpat_eks_production_cluster_name" {
  provider = aws.analytical-platform-management-production

  name = "dpat-eks/production/cluster/name"
}

data "aws_secretsmanager_secret_version" "dpat_eks_production_cluster_name" {
  provider = aws.analytical-platform-management-production

  secret_id = data.aws_secretsmanager_secret.dpat_eks_production_cluster_name.id
}

data "aws_secretsmanager_secret" "dpat_eks_production_cluster_ca_cert" {
  provider = aws.analytical-platform-management-production

  name = "dpat-eks/production/cluster/ca-cert"
}

data "aws_secretsmanager_secret_version" "dpat_eks_production_cluster_ca_cert" {
  provider = aws.analytical-platform-management-production

  secret_id = data.aws_secretsmanager_secret.dpat_eks_production_cluster_ca_cert.id
}

data "aws_secretsmanager_secret" "dpat_eks_production_cluster_endpoint" {
  provider = aws.analytical-platform-management-production

  name = "dpat-eks/production/cluster/endpoint"
}

data "aws_secretsmanager_secret_version" "dpat_eks_production_cluster_endpoint" {
  provider = aws.analytical-platform-management-production

  secret_id = data.aws_secretsmanager_secret.dpat_eks_production_cluster_endpoint.id
}
