##################################################
# Certificate Manager
##################################################

data "aws_iam_policy_document" "cert_manager" {
  statement {
    sid       = "certManagerGetChange"
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }
  statement {
    sid    = "certManagerResourceRecordSets"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.main.zone_id}"]
  }
}

resource "aws_iam_policy" "cert_manager" {
  name_prefix = "cert-manager"
  description = "cert-manager policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.cert_manager.json
}

##################################################
# Cluster Autoscaler
##################################################

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values   = ["owned"]
    }
    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

##################################################
# EKS EFS CSI Driver
##################################################

data "aws_iam_policy_document" "efs_csi_driver" {
  statement {
    sid    = "AmazonEKSEFSCSIDriverPolicy"
    effect = "Allow"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "efs_csi_driver" {
  name_prefix = "AmazonEKSEFSCSIDriverPolicy"
  description = "AmazonEKS_EFS_CSI_Driver_Policy for ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.efs_csi_driver.json
}

##################################################
# External DNS
##################################################

data "aws_iam_policy_document" "external_dns" {
  statement {
    sid       = "externalDNSListHostedZones"
    effect    = "Allow"
    actions   = ["route53:ListHostedZones"]
    resources = ["*"]
  }
  statement {
    sid    = "externalDNSResourceRecordSets"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.main.zone_id}"]
  }
}

resource "aws_iam_policy" "external_dns" {
  name_prefix = "external_dns"
  description = "external_dns policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.external_dns.json
}

##################################################
# External Secrets
##################################################

data "aws_iam_policy_document" "external_secrets" {
  statement {
    sid    = "externalSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = ["arn:aws:secretsmanager:eu-west-1:${var.account_ids["analytical-platform-development"]}:secret:*"]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name_prefix = "external_secrets"
  description = "external_secrets policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.external_secrets.json
}

##################################################
# JupyterHub
##################################################

data "aws_iam_policy_document" "jupyterhub_teama" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:ListAccessPoints",
      "s3:GetAccountPublicAccessBlock"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "readonly"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = ["arn:aws:s3:::dev-david-test-source/*"]
  }
  statement {
    sid    = "readwrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:RestoreObject"
    ]
    resources = ["arn:aws:s3:::dev-teama-*/*"]
  }
}

resource "aws_iam_policy" "jupyterhub_teama" {
  name        = "jupyterhub-teama"
  description = "jupyterhub-teama policy"
  policy      = data.aws_iam_policy_document.jupyterhub_teama.json
}

##################################################
# Prometheus Remote Ingest
##################################################

data "aws_iam_policy_document" "prometheus_remote_ingest" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/prometheus_central_ingest"]
  }
}

resource "aws_iam_policy" "prometheus_remote_ingest" {
  name        = "prometheus_remote_ingest"
  description = "Managed Prometheus remote ingest policy for cluster"
  policy      = data.aws_iam_policy_document.prometheus_remote_ingest.json
}

##################################################
# SuperSet
##################################################

data "aws_iam_policy_document" "superset" {
  statement {
    sid    = "GetObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = ["arn:aws:s3:::athena-examples-eu-west-1/*"]
  }

  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::athena-examples-eu-west-1"]
  }

}

resource "aws_iam_policy" "superset" {
  name_prefix = "superset"
  description = "superset policy"
  policy      = data.aws_iam_policy_document.superset.json
}

##################################################
# EKS EBS CSI Driver
##################################################

data "aws_iam_policy_document" "ebs_csi_driver" {
  statement {
    sid    = "EbsCsiDriver"
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ebs_csi_driver" {
  name_prefix = "EbsCsiDriver"
  description = "ebs_csi_driver policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.ebs_csi_driver.json

  tags = {
    cluster = local.eks_cluster_name
  }
}

##################################################
# Control Panel API
##################################################

data "aws_iam_policy_document" "control_panel_api" {
  statement {
    sid    = "CanCreateBuckets"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:PutBucketLogging",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketVersioning",
      "s3:PutLifecycleConfiguration",
      "s3:PutBucketPolicy"
    ]
    resources = ["arn:aws:s3:::${var.resource_prefix}-*"]
  }
  statement {
    sid    = "CanTagBuckets"
    effect = "Allow"
    actions = [
      "s3:GetBucketTagging",
      "s3:PutBucketTagging"
    ]
    resources = ["arn:aws:s3:::${var.resource_prefix}-*"]
  }
  statement {
    sid       = "CanCreateIAMPolicies"
    effect    = "Allow"
    actions   = ["iam:CreatePolicy"]
    resources = ["arn:aws:iam::${var.account_ids["analytical-platform-development"]}:policy/${var.resource_prefix}-*"]
  }
  statement {
    sid       = "CanDeleteIAMPolicies"
    effect    = "Allow"
    actions   = ["iam:DeletePolicy"]
    resources = ["arn:aws:iam::${var.account_ids["analytical-platform-development"]}:policy/${var.resource_prefix}-*"]
  }
  statement {
    sid     = "CanAttachPolicies"
    effect  = "Allow"
    actions = ["iam:AttachRolePolicy", ]
    resources = [
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_user_*",
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_app_*"
    ]
  }
  statement {
    sid    = "CanDetachPolicies"
    effect = "Allow"
    actions = [
      "iam:ListEntitiesForPolicy",
      "iam:DetachGroupPolicy",
      "iam:DetachRolePolicy",
      "iam:DetachUserPolicy"
    ]
    resources = ["arn:aws:iam::${var.account_ids["analytical-platform-development"]}:*"]
  }
  statement {
    sid     = "CanCreateRoles"
    effect  = "Allow"
    actions = ["iam:CreateRole"]
    resources = [
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_user_*",
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_app_*"
    ]
  }
  statement {
    sid    = "CanDeleteRoles"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:DeleteRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:DetachRolePolicy",
      "iam:DeleteRolePolicy"
    ]
    resources = [
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_user_*",
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_app_*"
    ]
  }
  statement {
    sid     = "CanReadRolesInlinePolicies"
    effect  = "Allow"
    actions = ["iam:GetRolePolicy"]
    resources = [
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_user_*",
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_app_*"
    ]
  }
  statement {
    sid     = "CanUpdateRolesInlinePolicies"
    effect  = "Allow"
    actions = ["iam:PutRolePolicy"]
    resources = [
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_user_*",
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_app_*"
    ]
  }
  statement {
    sid       = "CanUpdateAssumeRolesPolicies"
    effect    = "Allow"
    actions   = ["iam:UpdateAssumeRolePolicy"]
    resources = ["arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/${var.resource_prefix}_user_*"]
  }
  statement {
    sid    = "CanCreateAndDeleteSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath",
      "ssm:DeleteParameter",
      "ssm:DeleteParameters",
      "ssm:AddTagsToResource"
    ]
    resources = ["arn:aws:ssm:*:${var.account_ids["analytical-platform-development"]}:parameter/${var.resource_prefix}*"]
  }
  statement {
    sid       = "CanListRoles"
    effect    = "Allow"
    actions   = ["iam:ListRoles"]
    resources = ["arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/*"]
  }
  statement {
    sid    = "CanManagePolicies"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:ListPolicies",
      "iam:ListEntitiesForPolicy",
      "iam:DetachRolePolicy",
      "iam:AttachRolePolicy"
    ]
    resources = ["arn:aws:iam::${var.account_ids["analytical-platform-development"]}:policy/${var.resource_prefix}/group/*"]
  }
  statement {
    sid    = "CanManageSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:TagResource",
      "secretsmanager:UntagResource",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret",
      "secretsmanager:DeleteSecret"
    ]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${var.account_ids["analytical-platform-development"]}:secret:dev/apps/*"]
  }
  statement {
    sid    = "CanManageSqsMessages"
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]
    resources = ["arn:aws:sqs::${var.account_ids[var.target_account]}:*"]
  }
}

resource "aws_iam_policy" "control_panel_api" {
  name        = "dev_eks_control_panel_api"
  description = "Control Panel policy for ${var.resource_prefix} EKS cluster"
  policy      = data.aws_iam_policy_document.control_panel_api.json
}
