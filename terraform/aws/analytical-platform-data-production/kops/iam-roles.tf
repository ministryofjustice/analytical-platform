##################################################
# nodes.alpha.mojanalytics.xyz
##################################################

data "aws_iam_policy_document" "nodes_alpha_mojanalytics_xyz_additional" {
  statement {
    sid       = "AllowAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
  statement {
    sid    = "AllowECR"
    effect = "Allow"
    actions = [
      "ecr:DescribeImages",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:CreateRepository"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "nodes_alpha_mojanalytics_xyz_inline" {
  statement {
    sid    = "AllowEC2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowKopsS3GetBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration",
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::kops.analytics.justice.gov.uk"]
  }
  statement {
    sid       = "AllowKopsS3GetBucketObjects"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::kops.analytics.justice.gov.uk/alpha.mojanalytics.xyz/*"]
  }
  statement {
    sid       = "AllowRoute53Change"
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }
  statement {
    sid       = "AllowRoute53ListHostedZones"
    effect    = "Allow"
    actions   = ["route53:ListHostedZones"]
    resources = ["*"]
  }
  statement {
    sid    = "AllowAlphaMojanalyticsXyzRoute53"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:GetHostedZone"
    ]
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.alpha_mojanalytics_xyz.zone_id}"]
  }
  statement {
    sid    = "AllowECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "nodes_alpha_mojanalytics_xyz" {
  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
  statement {
    sid     = "AllowAlphaNodesAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nodes.alpha.mojanalytics.xyz"]
    }
  }
}

resource "aws_iam_role" "nodes_alpha_mojanalytics_xyz" {
  name               = "nodes.alpha.mojanalytics.xyz"
  assume_role_policy = data.aws_iam_policy_document.nodes_alpha_mojanalytics_xyz.json
  managed_policy_arns = [
    data.aws_iam_policy.access_mojap_non_sensitive_files_for_docker_builds.arn,
    data.aws_iam_policy.alpha_cluster_autoscaler.arn
  ]
  inline_policy {
    name   = "additional.nodes.alpha.mojanalytics.xyz"
    policy = data.aws_iam_policy_document.nodes_alpha_mojanalytics_xyz_additional.json
  }
  inline_policy {
    name   = "nodes.alpha.mojanalytics.xyz"
    policy = data.aws_iam_policy_document.nodes_alpha_mojanalytics_xyz_inline.json
  }
}

##################################################
# nodes.dev.mojanalytics.xyz
##################################################

data "aws_iam_policy_document" "nodes_dev_mojanalytics_xyz_additional" {
  statement {
    sid       = "AllowAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
  statement {
    sid    = "AllowECR"
    effect = "Allow"
    actions = [
      "ecr:DescribeImages",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:CreateRepository"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowSSM"
    effect = "Allow"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowSSMMessages"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowEC2Messages"
    effect = "Allow"
    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "nodes_dev_mojanalytics_xyz_inline" {
  statement {
    sid    = "AllowEC2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowKopsS3GetBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration",
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::kops.analytics.justice.gov.uk"]
  }
  statement {
    sid       = "AllowKopsS3GetBucketObjects"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::kops.analytics.justice.gov.uk/dev.mojanalytics.xyz/*"]
  }
  statement {
    sid       = "AllowRoute53Change"
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }
  statement {
    sid       = "AllowRoute53ListHostedZones"
    effect    = "Allow"
    actions   = ["route53:ListHostedZones"]
    resources = ["*"]
  }
  statement {
    sid    = "AllowAlphaMojanalyticsXyzRoute53"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:GetHostedZone"
    ]
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.dev_mojanalytics_xyz.zone_id}"]
  }
  statement {
    sid    = "AllowECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "nodes_dev_mojanalytics_xyz" {
  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
  statement {
    sid     = "AllowDevNodesAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nodes.dev.mojanalytics.xyz"]
    }
  }
}

resource "aws_iam_role" "nodes_dev_mojanalytics_xyz" {
  name               = "nodes.dev.mojanalytics.xyz"
  assume_role_policy = data.aws_iam_policy_document.nodes_dev_mojanalytics_xyz.json
  managed_policy_arns = [
    data.aws_iam_policy.access_mojap_non_sensitive_files_for_docker_builds.arn,
    data.aws_iam_policy.dev_cluster_autoscaler.arn
  ]
  inline_policy {
    name   = "additional.nodes.dev.mojanalytics.xyz"
    policy = data.aws_iam_policy_document.nodes_dev_mojanalytics_xyz_additional.json
  }
  inline_policy {
    name   = "nodes.dev.mojanalytics.xyz"
    policy = data.aws_iam_policy_document.nodes_dev_mojanalytics_xyz_inline.json
  }
}
