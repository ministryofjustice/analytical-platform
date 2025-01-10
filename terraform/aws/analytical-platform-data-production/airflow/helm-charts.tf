### Dev Resources

# resource "helm_release" "kyverno_dev" {
#   name       = "kyverno"
#   repository = "https://kyverno.github.io/kyverno/"
#   chart      = "kyverno"
#   version    = "2.6.0"
#   namespace  = kubernetes_namespace.kyverno_dev.metadata[0].name
#   provider   = helm.dev-airflow-cluster
#   values = [
#     templatefile(
#       "${path.module}/src/helm/kyverno/values.yml.tftpl", {}
#     )
#   ]
# }
/*
resource "helm_release" "kube2iam_dev" {
  name       = "kube2iam"
  repository = "https://jtblin.github.io/kube2iam"
  chart      = "kube2iam"
  version    = "32.0"
  namespace  = kubernetes_namespace.dev_kube2iam.metadata[0].name
  provider   = helm.dev-airflow-cluster
  values = [
    templatefile(
      "${path.module}/src/helm/kube2iam/values.yml.tftpl",
      {
        env = "dev"
      }
    )
  ]
} */

# resource "helm_release" "kube2iam_dev" {
#   name       = "kube2iam"
#   repository = "https://jtblin.github.io/kube2iam"
#   chart      = "kube2iam"
#   version    = "3.2.0"
#   namespace  = kubernetes_namespace.dev_kube2iam.metadata[0].name
#   provider   = helm.dev-airflow-cluster
#   values = [
#     templatefile(
#       "${path.module}/src/helm/kube2iam/values.yml.tftpl",
#       {
#         env = "dev"
#       }
#     )
#   ]
# }

resource "helm_release" "kyverno_prod" {
  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = "2.5.3"
  namespace  = kubernetes_namespace.kyverno_prod.metadata[0].name
  provider   = helm.prod-airflow-cluster
  values = [
    templatefile(
      "${path.module}/src/helm/kyverno/values.yml.tftpl", {}
    )
  ]
}

/*
We've replaced `kubernetes_manifest` with `kubectl_manifest` as it was erroring with
  produced an unexpected new value: .object: wrong final value │ type: attribute "spec": attribute "rules": tuple required.

resource "kubernetes_manifest" "kyverno_policy_disallow_escalation" {
  provider   = kubernetes.dev-airflow-cluster
  manifest   = yamldecode(file("${path.module}/files/kyverno_policies/kyv.privilege_escalation.yaml"))
  depends_on = [helm_release.kyverno_dev]
}

resource "kubernetes_manifest" "kyverno_policy_run_as_non_root" {
  provider   = kubernetes.dev-airflow-cluster
  manifest   = yamldecode(file("${path.module}/files/kyverno_policies/kyv.run_as_non_root.yaml"))
  depends_on = [helm_release.kyverno_dev]
}

resource "kubernetes_manifest" "kyverno_policy_run_as_non_root_user" {
  provider   = kubernetes.dev-airflow-cluster
  manifest   = yamldecode(file("${path.module}/files/kyverno_policies/kyv.run_as_non_root_user.yaml"))
  depends_on = [helm_release.kyverno_dev]
}
*/

# resource "kubectl_manifest" "kyverno_policy_disallow_escalation_dev" {
#   provider  = kubectl.dev-airflow-cluster
#   yaml_body = file("${path.module}/files/kyverno_policies/kyv.privilege_escalation.yaml")

#   depends_on = [helm_release.kyverno_dev]
# }

# resource "kubectl_manifest" "kyverno_policy_run_as_non_root_dev" {
#   provider  = kubectl.dev-airflow-cluster
#   yaml_body = file("${path.module}/files/kyverno_policies/kyv.run_as_non_root.yaml")

#   depends_on = [helm_release.kyverno_dev]
# }

# resource "kubectl_manifest" "kyverno_policy_run_as_non_root_user_dev" {
#   provider  = kubectl.dev-airflow-cluster
#   yaml_body = file("${path.module}/files/kyverno_policies/kyv.run_as_non_root_user.yaml")

#   depends_on = [helm_release.kyverno_dev]
# }

resource "kubectl_manifest" "kyverno_policy_disallow_escalation_prod" {
  provider  = kubectl.prod-airflow-cluster
  yaml_body = file("${path.module}/files/kyverno_policies/kyv.privilege_escalation.yaml")

  depends_on = [helm_release.kyverno_prod]
}

resource "kubectl_manifest" "kyverno_policy_run_as_non_root_prod" {
  provider  = kubectl.prod-airflow-cluster
  yaml_body = file("${path.module}/files/kyverno_policies/kyv.run_as_non_root.yaml")

  depends_on = [helm_release.kyverno_prod]
}

resource "kubectl_manifest" "kyverno_policy_run_as_non_root_user_prod" {
  provider  = kubectl.prod-airflow-cluster
  yaml_body = file("${path.module}/files/kyverno_policies/kyv.run_as_non_root_user.yaml")

  depends_on = [helm_release.kyverno_prod]
}

