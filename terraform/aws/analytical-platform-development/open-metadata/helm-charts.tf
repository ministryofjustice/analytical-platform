resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.29.1"
  namespace  = "kube-system"
  values = [
    templatefile(
      "${path.module}/src/helm/cluster-autoscaler/values.yml.tftpl",
      {
        aws_region   = data.aws_region.current.name
        cluster_name = module.eks.cluster_name
        eks_role_arn = module.cluster_autoscaler_iam_role.iam_role_arn
      }
    )
  ]
}

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

resource "helm_release" "amazon_managed_prometheus_proxy" {
  name       = "prometheus-proxy"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "23.1.0"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/prometheus/values.yml.tftpl",
      {
        aws_region                  = data.aws_region.current.name
        eks_role_arn                = module.amazon_managed_prometheus_iam_role.iam_role_arn
        prometheus_remote_write_url = "${module.managed_prometheus.workspace_prometheus_endpoint}api/v1/remote_write"
      }
    )
  ]
}

resource "helm_release" "auth0_exporter" {
  name       = "auth0-exporter"
  repository = "https://tfadeyi.github.io/auth0-simple-exporter"
  chart      = "auth0-exporter"
  version    = "0.0.2"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/auth0-exporter/values.yml.tftpl",
      {
        auth0_domain        = "alpha-analytics-moj.eu.auth0.com"
        auth0_client_id     = ""
        auth0_client_secret = ""
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
        openmetadata_airflow_password                = random_password.openmetadata_airflow.result
        openmetadata_airflow_eks_role_arn            = module.open_metadata_airflow_iam_role.iam_role_arn
        openmetadata_airflow_rds_host                = module.airflow_rds.db_instance_address
        openmetadata_airflow_rds_user                = module.airflow_rds.db_instance_username
        openmetadata_airflow_rds_password_secret     = kubernetes_secret.openmetadata_airflow_rds_credentials.metadata[0].name
        openmetadata_airflow_rds_password_secret_key = "password"
      }
    )
  ]
  wait    = true
  timeout = 600

  depends_on = [kubernetes_secret.openmetadata_airflow]
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
        namespace                                      = kubernetes_namespace.open_metadata.metadata[0].name
        host                                           = "open-metadata.data-platform.moj.woffenden.dev"
        acm_certificate_arn                            = aws_acm_certificate_validation.open_metadata.certificate_arn
        eks_role_arn                                   = module.open_metadata_iam_role.iam_role_arn
        client_id                                      = data.aws_secretsmanager_secret_version.open_metadata_client_id.secret_string
        tenant_id                                      = data.aws_secretsmanager_secret_version.open_metadata_tenant_id.secret_string
        jwt_key_id                                     = random_uuid.openmetadata_jwt.result
        openmetadata_elasticsearch_host                = resource.aws_opensearch_domain.openmetadata.endpoint
        openmetadata_elasticsearch_user                = "openmetadata"
        openmetadata_elasticsearch_password_secret     = kubernetes_secret.openmetadata_opensearch.metadata[0].name
        openmetadata_elasticsearch_password_secret_key = "password"
        openmetadata_rds_host                          = module.rds.db_instance_address
        openmetadata_rds_user                          = module.rds.db_instance_username
        openmetadata_rds_password_secret               = kubernetes_secret.openmetadata_rds_credentials.metadata[0].name
        openmetadata_rds_password_secret_key           = "password"
      }
    )
  ]
  wait    = true
  timeout = 600

  depends_on = [helm_release.openmetadata_dependencies, aws_acm_certificate_validation.open_metadata]
}
