resource "kubernetes_persistent_volume_claim" "airflow_dags" {
  metadata {
    name      = "openmetadata-dependencies-dags-pvc"
    namespace = kubernetes_namespace.open_metadata.metadata[0].name
    labels = {
      app = "airflow-dags"
    }
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = ""
    volume_name        = kubernetes_persistent_volume.airflow_dags.metadata[0].name
  }
  wait_until_bound = false
}

resource "kubernetes_persistent_volume_claim" "airflow_logs" {
  metadata {
    name      = "openmetadata-dependencies-logs-pvc"
    namespace = kubernetes_namespace.open_metadata.metadata[0].name
    labels = {
      app = "airflow-logs"
    }
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    storage_class_name = ""
    volume_name        = kubernetes_persistent_volume.airflow_logs.metadata[0].name
  }
  wait_until_bound = false
}
