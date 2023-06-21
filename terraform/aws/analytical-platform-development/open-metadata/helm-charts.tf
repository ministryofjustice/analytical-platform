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

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.5.3"
  namespace  = "kube-system"
  values = [
    templatefile(
      "${path.module}/src/helm/aws-load-balancer-controller/values.yml.tftpl",
      {
        cluster_name = module.eks.cluster_name
        eks_role_arn = module.load_balancer_controller_iam_role.iam_role_arn
      }
    )
  ]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.12.0"
  namespace  = "cert-manager"
  values = [
    templatefile(
      "${path.module}/src/helm/cert-manager/values.yml.tftpl",
      {
        eks_role_arn = module.cert_manager_iam_role.iam_role_arn
      }
    )
  ]
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.13.0"
  namespace  = "external-dns"
  values = [
    templatefile(
      "${path.module}/src/helm/external-dns/values.yml.tftpl",
      {
        domain_filter = "data-platform.moj.woffenden.dev"
        eks_role_arn  = module.external_dns_iam_role.iam_role_arn
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
  values = [
    templatefile(
      "${path.module}/src/helm/openmetadata/values.yml.tftpl",
      {
        host                = "open-metadata.data-platform.moj.woffenden.dev"
        acm_certificate_arn = aws_acm_certificate_validation.open_metadata.certificate_arn
      }
    )
  ]
  wait = false /* this is temporary */

  depends_on = [helm_release.openmetadata_dependencies, aws_acm_certificate_validation.open_metadata]
}
