resource "kubernetes_secret" "coder_rds_connection_url" {
  metadata {
    name      = "coder-rds-connection-url"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
  data = {
    # "url" = "postgres://${local.coder_rds_credentials.username}:${local.coder_rds_credentials.password}@${module.coder_rds.db_instance_address}:${module.coder_rds.db_instance_port}/${module.coder_rds.db_instance_name}"
    url = "postgres://${module.coder_rds.db_instance_username}:${random_password.coder_rds_password.result}@${module.coder_rds.db_instance_address}:${module.coder_rds.db_instance_port}/${module.coder_rds.db_instance_name}"
  }
  type = "Opaque"
}
