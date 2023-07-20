resource "kubernetes_secret" "openmetadata_opensearch" {
  metadata {
    name      = "opensearch-credentials"
    namespace = kubernetes_namespace.open_metadata.metadata[0].name
  }
  data = {
    password = random_password.opensearch_master_password.result
  }
  type = "Opaque"
}

resource "kubernetes_secret" "openmetadata_airflow" {
  metadata {
    name      = "airflow-secrets"
    namespace = kubernetes_namespace.open_metadata.metadata[0].name
  }
  data = {
    openmetadata-airflow-password = random_password.openmetadata_airflow.result
  }
  type = "Opaque"
}

resource "kubernetes_secret" "openmetadata_airflow_rds_credentials" {
  metadata {
    name      = "openmetadata-airflow-rds-credentials"
    namespace = kubernetes_namespace.open_metadata.metadata[0].name
  }
  data = {
    username = local.openmetadata_airflow_rds_credentials.username
    password = local.openmetadata_airflow_rds_credentials.password
  }
  type = "Opaque"
}

resource "kubernetes_secret" "openmetadata_rds_credentials" {
  metadata {
    name      = "openmetadata-rds-credentials"
    namespace = kubernetes_namespace.open_metadata.metadata[0].name
  }
  data = {
    username = local.openmetadata_rds_credentials.username
    password = local.openmetadata_rds_credentials.password
  }
  type = "Opaque"
}

/*
I've created this manually because the file() function cannot parse binary files, and filebase64() creates them on disk as base64 encoded

These files have been moved to 1Password

kubectl \
  --namespace open-metadata \
  create \
  secret \
  generic \
  openmetadata-jwt-tls \
  --from-file=private-key.der=./src/tls/openmetadata/jwt/private-key.der \
  --from-file=public-key.der=src/tls/openmetadata/jwt/public-key.der

resource "kubernetes_secret" "openmetadata_jwt_tls" {
  metadata {
    name      = "openmetadata-jwt-tls"
    namespace = kubernetes_namespace.open_metadata.metadata[0].name
  }
  data = {
    "private-key.der" = filebase64("${path.module}/src/tls/openmetadata/jwt/private-key.der")
    "public-key.der"  = filebase64("${path.module}/src/tls/openmetadata/jwt/public-key.der")
  }
  type = "Opaque"
}
*/

resource "kubernetes_secret" "coder_rds_connection_url" {
  metadata {
    name      = "coder-rds-connection-url"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
  data = {
    "url" = "postgres://${local.coder_rds_credentials.username}:${local.coder_rds_credentials.password}@${module.coder_rds.db_instance_address}:${module.coder_rds.db_instance_port}/${module.coder_rds.db_instance_name}"
  }
  type = "Opaque"
}
