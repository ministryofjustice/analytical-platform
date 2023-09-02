module "karpenter" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "19.15.3"

  cluster_name = local.eks_cluster_name

  create_irsa     = false
  create_iam_role = true
}

resource "aws_security_group" "karpenter" {
  description = "Provides karpenter with a map of subnets to deploy nodes"
  vpc_id      = module.vpc.vpc_id

  tags = {
    "karpenter.sh/discovery" = local.eks_cluster_name
  }
}

resource "aws_security_group_rule" "karpenter" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.karpenter.id
  security_group_id        = aws_security_group.karpenter.id
}

resource "aws_security_group_rule" "eks_node_karpenter" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.eks.worker_security_group_id
  security_group_id        = aws_security_group.karpenter.id
}

resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

data "aws_iam_policy_document" "karpenter_controller" {
  statement {
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:CreateTags",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
      "pricing:GetProducts",
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
    ]

    resources = ["*"]
  }

  statement {
    actions = ["ec2:RunInstances"]
    resources = [
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*",
    ]
  }

  statement {
    actions = ["ec2:RunInstances"]
    resources = [
      "arn:aws:ec2:*::image/*",
      "arn:aws:ec2:*::snapshot/*",
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:spot-instances-request/*",
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*",
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:network-interface/*",
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*",
    ]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:*:parameter/aws/service/*"]
  }

  statement {
    actions   = ["eks:DescribeCluster"]
    resources = [module.eks.cluster_arn]
  }

  statement {
    actions   = ["iam:PassRole"]
    resources = [module.karpenter.role_arn]
  }

  statement {
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
    resources = [module.karpenter.queue_arn]
  }
}

resource "aws_iam_policy" "karpenter_irsa" {
  name        = "karpenter_controller"
  path        = "/"
  description = "Karpenter controller policy"

  policy = data.aws_iam_policy_document.karpenter_controller.json
}

module "iam_karpenter_controller_irsa" {
  source                         = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                        = "5.30.0"
  create_role                    = true
  role_name_prefix               = "karpenter_controller"
  provider_url                   = module.eks.cluster_oidc_issuer_url
  role_policy_arns               = [aws_iam_policy.karpenter_irsa.arn]
  oidc_fully_qualified_subjects  = ["system:serviceaccount:karpenter:karpenter"]
  oidc_fully_qualified_audiences = ["sts.amazonaws.com"]
}
