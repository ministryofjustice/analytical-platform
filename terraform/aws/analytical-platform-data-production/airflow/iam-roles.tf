module "airflow_analytical_platform_development_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.28.0"

  create_role = true

  role_name = "airflow-analytical-platform-development"

  role_policy_arns = {
    policy = module.airflow_analytical_platform_development_iam_policy.arn
  }

  oidc_providers = {
    one = {
      provider_arn               = resource.aws_iam_openid_connect_provider.analytical_platform_development.arn
      namespace_service_accounts = ["airflow:airflow"]
    }
  }
}
# airflow execution role
resource "aws_iam_role" "airflow_dev_execution_role" {
  name               = "airflow-dev-execution-role"
  description        = "Execution role for Airflow dev"
  assume_role_policy = data.aws_iam_policy_document.airflow_dev_execution_assume_role_policy.json

  inline_policy {
    name   = "airflow-dev-execution-role-policy"
    policy = data.aws_iam_policy_document.airflow_dev_execution_role_policy.json
  }
}
# airflow auto cluster role
resource "aws_iam_role" "airflow_dev_cluster_autoscaler_role" {
  name               = "airflow-dev-cluster-autoscaler-role"
  description        = "Cluster Autoscaler role for Airflow dev"
  assume_role_policy = data.aws_iam_policy_document.airflow_dev_cluster_autoscaler_assume_role_policy.json

  inline_policy {
    name   = "cluster-autoscaler"
    policy = data.aws_iam_policy_document.airflow_dev_cluster_autoscaler_policy.json
  }
}

# flow log role
resource "aws_iam_role" "airflow_dev_flow_log_role" {
  name               = "airflow-dev-flow-log-role"
  description        = "Flow log role for Airflow dev"
  assume_role_policy = data.aws_iam_policy_document.airflow_dev_flow_log_assume_policy.json

  inline_policy {
    name   = "airflow-dev-flow-log-policy"
    policy = data.aws_iam_policy_document.airflow_dev_flow_log_role_policy.json
  }
}
# airflow node instace role

resource "aws_iam_role" "airflow_dev_node_instance_role" {
  name               = "airflow-dev-node-instance-role"
  description        = "Node execution role for Airflow dev"
  assume_role_policy = data.aws_iam_policy_document.airflow_dev_node_instance_assume_role_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  inline_policy {
    name   = "airflow-dev-node-instance-role-policy"
    policy = data.aws_iam_policy_document.airflow_dev_node_instance_inline_role_policy.json
  }
}

# airflow default pod role

resource "aws_iam_role" "airflow_dev_default_pod_role" {
  name               = "airflow-dev-default-pod-role"
  description        = "Default pod role for Airflow dev"
  assume_role_policy = data.aws_iam_policy_document.airflow_dev_default_pod_role_policy.json

}

