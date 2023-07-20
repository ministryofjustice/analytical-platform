resource "kubernetes_secret" "coder_rds_connection_url" {
  metadata {
    name      = "coder-rds-connection-url"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
  data = {
    url = "postgres://${module.coder_rds.db_instance_username}:${random_password.coder_rds_password.result}@${module.coder_rds.db_instance_address}:${module.coder_rds.db_instance_port}/${module.coder_rds.db_instance_name}"
  }
  type = "Opaque"
}

resource "kubernetes_secret" "coder_azuread_client_id" {
  metadata {
    name      = "coder-azuread-client-id"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
  data = {
    string = data.aws_secretsmanager_secret_version.coder_azuread_client_id.secret_string
  }
  type = "Opaque"
}

resource "kubernetes_secret" "coder_azuread_client_secret" {
  metadata {
    name      = "coder-azuread-client-secret"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
  data = {
    string = data.aws_secretsmanager_secret_version.coder_azuread_client_secret.secret_string
  }
  type = "Opaque"
}

resource "kubernetes_secret" "coder_azuread_issuer_url" {
  metadata {
    name      = "coder-azuread-issuer-url"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
  data = {
    string = data.aws_secretsmanager_secret_version.coder_azuread_issuer_url.secret_string
  }
  type = "Opaque"
}
