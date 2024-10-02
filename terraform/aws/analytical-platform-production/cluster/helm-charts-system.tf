resource "helm_release" "aws_for_fluent_bit" {
  /* https://artifacthub.io/packages/helm/aws/aws-for-fluent-bit */
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = "0.1.34"
  namespace  = kubernetes_namespace.aws_observability.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/aws-for-fluent-bit/values.yml.tftpl",
      {
        aws_region                = data.aws_region.current.name
        cluster_name              = local.eks_cluster_name
        cloudwatch_log_group_name = module.eks_log_group.cloudwatch_log_group_name
        eks_role_arn              = module.aws_for_fluent_bit_iam_role.iam_role_arn
      }
    )
  ]

  depends_on = [module.aws_for_fluent_bit_iam_role]
}

resource "helm_release" "amazon_prometheus_proxy" {
  /* https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack */
  /*
    If you are upgrading this chart, check whether the CRD version needs updating
    https://github.com/prometheus-operator/prometheus-operator/releases
  */
  name       = "amazon-prometheus-proxy"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "62.7.0"
  namespace  = kubernetes_namespace.aws_observability.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/amazon-prometheus-proxy/values.yml.tftpl",
      {
        aws_region       = data.aws_region.current.name
        eks_role_arn     = module.amazon_prometheus_proxy_iam_role.iam_role_arn
        amp_workspace_id = module.managed_prometheus.workspace_id
      }
    )
  ]

  depends_on = [
    kubernetes_manifest.prometheus_operator_crds,
    module.amazon_prometheus_proxy_iam_role
  ]
}
