##################################################
# EKS EFS CSI Driver
##################################################

data "aws_iam_policy_document" "efs_csi_driver_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "oidc.eks.eu-west-1.amazonaws.com/id/DDE7A0AC243F2E06BD539D26B3EC28A6:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::525294151996:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/DDE7A0AC243F2E06BD539D26B3EC28A6"]
    }
  }
}

resource "aws_iam_role" "efs_csi_driver" {
  name_prefix        = "AmazonEKSEFSCSIDriverRole"
  description        = "Role to allow EKS to control EFS"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_driver_assume.json
}

resource "aws_iam_policy_attachment" "efs_csi_driver" {
  name       = "AmazonEKSEFSCSIDriverRolePolicyAttachment"
  roles      = [aws_iam_role.efs_csi_driver.name]
  policy_arn = aws_iam_policy.efs_csi_driver.arn
}

##################################################
# Prometheus Central Ingest
##################################################

data "aws_iam_policy_document" "prometheus_central_ingest" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/prometheus_remote_ingest",
        "arn:aws:iam::${var.account_ids["analytical-platform-production"]}:role/prometheus_remote_ingest"
      ]
    }
  }
}

resource "aws_iam_role" "prometheus_central_ingest" {
  name               = "prometheus_central_ingest"
  assume_role_policy = data.aws_iam_policy_document.prometheus_central_ingest.json
}

resource "aws_iam_role_policy_attachment" "prometheus_central_ingest" {
  role       = aws_iam_role.prometheus_central_ingest.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
}

resource "aws_iam_role_policy_attachment" "prometheus_lake_formation_data_access" {
  role       = aws_iam_role.prometheus_central_ingest.name
  policy_arn = data.aws_iam_policy.lake_formation_data_access.arn
}

##################################################
# RDS Enhanced Monitoring
##################################################

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix        = "rds-enhanced-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring.json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_role_policy_attachment" "rds_lake_formation_data_access" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = data.aws_iam_policy.lake_formation_data_access.arn
}

##################################################
# Cert Manager
##################################################

module "iam_assumable_role_cert_manager" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name_prefix              = "cert_manager"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cert_manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:cert-manager:cert-manager"]
}

##################################################
# Cluster Autoscaler
##################################################

module "iam_assumable_role_cluster_autoscaler" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name_prefix              = substr("cluster-autoscaler-${module.eks.cluster_id}", 0, 31)
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cluster-autoscaler"]
}

##################################################
# EBS CSI Driver
##################################################

module "iam_assumable_role_ebs_csi_driver" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source                   = "github.com/ministryofjustice/ap-terraform-iam-roles//eks-role?ref=v1.4.2"
  role_name_prefix         = "EbsCsiDriver"
  role_description         = "ebs_csi_driver role for cluster ${module.eks.cluster_id}"
  role_policy_arns         = [aws_iam_policy.ebs_csi_driver.arn]
  provider_url             = module.eks.cluster_oidc_issuer_url
  cluster_service_accounts = ["kube-system:ebs-csi-controller-sa"]
}

##################################################
# External DNS
##################################################

module "iam_assumable_role_external_dns" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name_prefix              = "external_dns"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:external-dns:external-dns"]
}

##################################################
# External Secrets
##################################################

module "iam_assumable_role_external_secrets" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name_prefix              = "external_secrets"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_secrets.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:external-secrets:external-secrets"]
}

##################################################
# JupyterHub
##################################################

module "iam_assumable_role_jupyterhub_teama" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name                     = "jupyterhub-teama"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.jupyterhub_teama.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:teama:jupyterhub"]
}

##################################################
# Amazon Managed Prometheus
##################################################

module "iam_assumable_role_prometheus_remote_ingest" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name                     = "prometheus_remote_ingest"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.prometheus_remote_ingest.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:prometheus:prometheus"]
}

##################################################
# SuperSet
##################################################

module "iam_assumable_role_superset" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.60.0"
  create_role                   = true
  role_name_prefix              = "superset"
  provider_url                  = "oidc.eks.eu-west-1.amazonaws.com/id/DDE7A0AC243F2E06BD539D26B3EC28A6"
  role_policy_arns              = [aws_iam_policy.superset.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:superset:default"]
}

##################################################
# Control Panel API
##################################################

module "iam_assumable_role_control_panel_api" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "5.60.0"
  create_role      = true
  role_name_prefix = "dev_control_panel_api"
  provider_url     = module.eks.cluster_oidc_issuer_url
  role_policy_arns = [aws_iam_policy.control_panel_api.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${var.control_panel_kubernetes_service_account}",
    "system:serviceaccount:${var.control_panel_celery_kubernetes_service_account}",
    "system:serviceaccount:${var.control_panel_celery_beat_kubernetes_service_account}",
  ]
}
