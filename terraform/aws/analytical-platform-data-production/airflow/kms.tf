data "aws_organizations_organization" "moj_root_account" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "s3_mojap_airflow_dev" {
  description             = "s3-logging-cloudtrail"
  policy                  = data.aws_iam_policy_document.kms_mojap_airflow_dev.json
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "s3_mojap_airflow_dev" {
  name          = "alias/mojap_airflow_dev"
  target_key_id = aws_kms_key.s3_mojap_airflow_dev.id
}


data "aws_iam_policy_document" "kms_mojap_airflow_dev" {
  #checkov:skip=CKV_AWS_356: Needs access to multiple resources
  #checkov:skip=CKV_AWS_111: Needs access to multiple resources
  #checkov:skip=CKV_AWS_109: low severity
  #checkov:skip=CKV_AWS_283: Ensure no IAM policies documents allow ALL or any AWS principal permissions to the resource

  statement {
    sid    = "Allow management of the key by this account"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }

  statement {
    sid    = "Enable decrypt access to accounts within the organisation"
    effect = "Allow"
    actions = [
      "kms:Describe*",
      "kms:Decrypt*"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values = [
        data.aws_organizations_organization.moj_root_account.id
      ]
    }
  }

  statement {
    sid    = "Allow use of the key including encryption"
    effect = "Allow"
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt*",
      "kms:Describe*",
      "kms:Decrypt*"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

}

##################################################
# EKS Encryption Key
##################################################

resource "aws_kms_key" "eks" {
  description         = "EKS Secret Encryption Key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.eks.json
}

resource "aws_kms_alias" "eks" {
  name          = "alias/eks"
  target_key_id = aws_kms_key.eks.key_id
}
data "aws_iam_policy_document" "eks" {
  # checkov:skip=CKV_AWS_356: "policy is directly related to the resource"
  # checkov:skip=CKV_AWS_111: "policy is directly related to the resource"
  # checkov:skip=CKV_AWS_109: "role is resticted by limited actions in member account"
  #checkov:skip=CKV_AWS_283: Ensure no IAM policies documents allow ALL or any AWS principal permissions to the resource

  statement {
    sid    = "Allow management access of the key by this account"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
  statement {
    sid    = "Allow use of the key including encryption"
    effect = "Allow"
    actions = [
      "kms:Decrypt*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
##################################################
# cloudwatch Encryption Key
##################################################

resource "aws_kms_key" "cloudwatch" {
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudwatch.json
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}
data "aws_iam_policy_document" "cloudwatch" {
  # checkov:skip=CKV_AWS_356: "policy is directly related to the resource"
  # checkov:skip=CKV_AWS_111: "policy is directly related to the resource"
  # checkov:skip=CKV_AWS_109: "role is resticted by limited actions in member account"
  #checkov:skip=CKV_AWS_283: Ensure no IAM policies documents allow ALL or any AWS principal permissions to the resource

  statement {
    sid    = "Allow management access of the key by this account"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
  statement {
    sid    = "Allow use of the key including encryption"
    effect = "Allow"
    actions = [
      "kms:Decrypt*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
