module "vpc_flow_logs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases                 = ["vpc-flow-logs"]
  description             = "VPC flow logs KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7
  key_statements = [
    {
      sid = "AllowCloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "ArnEquals"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc-flow-log/*"]
        }
      ]
    }
  ]
}

module "eks_cluster_logs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases                 = ["eks-cluster-logs"]
  description             = "EKS cluster logs KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7
  key_statements = [
    {
      sid = "AllowCloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "ArnEquals"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/development/cluster"]
        }
      ]
    }
  ]
}

module "ebs_kms_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases                 = ["eks-ebs"]
  description             = "EKS EBS KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7
  key_service_roles_for_autoscaling = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    module.eks.cluster_iam_role_arn
  ]
}

# module "container_insights_logs_kms" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

#   source  = "terraform-aws-modules/kms/aws"
#   version = "2.2.1"

#   aliases                 = ["container-insights-logs"]
#   description             = "AWS Container Insights logs KMS key"
#   enable_default_policy   = true
#   deletion_window_in_days = 7
#   key_statements = [
#     {
#       sid = "AllowCloudWatchLogs"
#       actions = [
#         "kms:Encrypt*",
#         "kms:Decrypt*",
#         "kms:ReEncrypt*",
#         "kms:GenerateDataKey*",
#         "kms:Describe*"
#       ]
#       resources = ["*"]
#       effect    = "Allow"
#       principals = [
#         {
#           type        = "Service"
#           identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
#         }
#       ]
#       conditions = [
#         {
#           test     = "ArnEquals"
#           variable = "kms:EncryptionContext:aws:logs:arn"
#           values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/containerinsights/*"]
#         }
#       ]
#     },
#     {
#       sid = "AllowObservabilityRole"
#       actions = [
#         "kms:Encrypt*",
#         "kms:Decrypt*",
#         "kms:ReEncrypt*",
#         "kms:GenerateDataKey*",
#         "kms:Describe*"
#       ]
#       resources = ["*"]
#       effect    = "Allow"
#       principals = [
#         {
#           type        = "AWS"
#           identifiers = [module.amazon_cloudwatch_observability_iam_role.iam_role_arn]
#         }
#       ]

#     }
#   ]
# }
