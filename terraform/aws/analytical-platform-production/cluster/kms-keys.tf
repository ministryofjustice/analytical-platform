##################################################
# EKS Encryption Key
##################################################

resource "aws_kms_key" "eks" {
  description         = "EKS Secret Encryption Key"
  enable_key_rotation = true
}

module "eks_cluster_logs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases                 = ["eks/cluster-logs"]
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
          values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/*"]
        }
      ]
    }
  ]
}

module "managed_prometheus_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases                 = ["amp/default"]
  description             = "AMP KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7
  key_statements = [
    {
      sid = "AllowAmazonManagedPrometheus"
      actions = [
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["aps.${data.aws_region.current.name}.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  ]
}

module "managed_prometheus_logs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases                 = ["amp/logs"]
  description             = "AMP logs KMS key"
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
          values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/amp/analytical-platform-production*"]
        }
      ]
    }
  ]
}
