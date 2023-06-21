resource "random_password" "openmetadata_airflow" {
  length  = 32
  special = false
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

resource "random_password" "openmetadata_mysql" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "openmetadata_mysql" {
  metadata {
    name      = "mysql-secrets"
    namespace = kubernetes_namespace.open_metadata.metadata[0].name
  }
  data = {
    openmetadata-mysql-password = random_password.openmetadata_mysql.result
  }
  type = "Opaque"
}

resource "random_password" "openmetadata_airflow_mysql" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "openmetadata_airflow_mysql" {
  metadata {
    name      = "airflow-mysql-secrets"
    namespace = kubernetes_namespace.open_metadata.metadata[0].name
  }
  data = {
    airflow-mysql-password = random_password.openmetadata_airflow_mysql.result
  }
  type = "Opaque"
}
