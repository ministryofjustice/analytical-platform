##################################################
# Cert Manager
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
    resources = ["arn:aws:secretsmanager:eu-west-1:${data.aws_caller_identity.current.account_id}:secret:*"]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name_prefix = "external_secrets"
  description = "external_secrets policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.external_secrets.json
}
