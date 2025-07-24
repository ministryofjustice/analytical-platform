####################################################################################
######################### AIRFLOW PRODUCTION INFRASTRUCTURE ########################
####################################################################################

resource "aws_iam_role" "airflow_prod_execution_role" {
  name               = "airflow-prod-execution-role"
  description        = "Execution role for Airflow"
  assume_role_policy = data.aws_iam_policy_document.airflow_prod_execution_assume_role_policy.json

  inline_policy {
    name   = "airflow-prod-execution-role-policy"
    policy = data.aws_iam_policy_document.airflow_prod_execution_role_policy.json
  }
}

resource "aws_iam_role" "airflow_prod_flow_log_role" {
  name               = "airflow-prod-flow-log-role"
  description        = "Flow log role for Airflow Prod"
  assume_role_policy = data.aws_iam_policy_document.airflow_prod_flow_log_assume_policy.json

  inline_policy {
    name   = "airflow-prod-flow-log-policy"
    policy = data.aws_iam_policy_document.airflow_prod_flow_log_role_policy.json
  }
}

resource "aws_iam_role" "airflow_prod_node_instance_role" {
  name               = "airflow-prod-node-instance-role"
  description        = "Node execution role for Airflow prod"
  assume_role_policy = data.aws_iam_policy_document.airflow_prod_node_instance_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  inline_policy {
    name   = "airflow-prod-node-instance-role-policy"
    policy = data.aws_iam_policy_document.airflow_prod_node_instance_inline_role_policy.json
  }
}

resource "aws_iam_role" "airflow_prod_eks_role" {
  name               = var.prod_eks_role_name
  description        = "Allows EKS to manage clusters on your behalf."
  assume_role_policy = data.aws_iam_policy_document.airflow_prod_eks_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]
}
