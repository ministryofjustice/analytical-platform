resource "helm_release" "aws_efs_csi_driver" {
  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  version    = "2.4.6"
  namespace  = "kube-system"
  values = [
    templatefile(
      "${path.module}/src/helm/aws-efs-csi-driver/values.yml.tftpl",
      {
        eks_role_arn = module.efs_csi_driver_iam_role.iam_role_arn
      }
    )
  ]
}

resource "helm_release" "openmetadata_dependencies" {
  name       = "openmetadata-dependencies"
  repository = "https://helm.open-metadata.org"
  chart      = "openmetadata-dependencies"
  version    = "1.0.6"
  namespace  = kubernetes_namespace.open_metadata.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/openmetadata-dependencies/values.yml.tftpl",
      {
        openmetadata_mysql_password         = random_password.openmetadata_mysql.result
        openmetadata_airflow_mysql_password = random_password.openmetadata_airflow_mysql.result
      }
    )
  ]
  wait = false /* this is temporary */

  depends_on = [kubernetes_secret.openmetadata_airflow, kubernetes_secret.openmetadata_mysql, kubernetes_secret.openmetadata_airflow_mysql]
}

resource "helm_release" "openmetadata" {
  name       = "openmetadata"
  repository = "https://helm.open-metadata.org"
  chart      = "openmetadata"
  version    = "1.0.6"
  namespace  = kubernetes_namespace.open_metadata.metadata[0].name
  wait       = false /* this is temporary */

  depends_on = [helm_release.openmetadata_dependencies]
}
