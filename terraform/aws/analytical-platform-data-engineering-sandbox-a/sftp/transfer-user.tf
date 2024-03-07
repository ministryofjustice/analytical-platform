data "aws_iam_policy_document" "transfer_user_jacobwoffenden" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
    ]
    resources = [module.s3_landing_kms.key_arn]
  }
  # TODO: review the permissions
  statement {
    sid     = "AllowS3ListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${module.landing_bucket.s3_bucket_id}",
      "arn:aws:s3:::${module.landing_bucket.s3_bucket_id}/jacobwoffenden/*"
    ]
  }
  # TODO: review the permissions
  statement {
    sid       = "AllowS3ObjectActions"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${module.landing_bucket.s3_bucket_id}/jacobwoffenden/*"]
  }
}

module "transfer_user_jacobwoffenden_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name_prefix = "transfer-user-jacobwoffenden"

  policy = data.aws_iam_policy_document.transfer_user_jacobwoffenden.json
}

module "transfer_user_jacobwoffenden_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  create_role = true

  role_name         = "transfer-user-jacobwoffenden"
  role_requires_mfa = false

  trusted_role_services = ["transfer.amazonaws.com"]

  custom_role_policy_arns = [module.transfer_user_jacobwoffenden_policy.arn]
}

resource "aws_transfer_user" "jacobwoffenden" {
  server_id = aws_transfer_server.this.id
  user_name = "jacobwoffenden"
  role      = module.transfer_user_jacobwoffenden_role.iam_role_arn

  # This doesn't work unless optimised directory is disabled
  # home_directory_type = "LOGICAL"
  # home_directory_mappings {
  #   entry  = "/upload"
  #   target = "/${module.landing_bucket.s3_bucket_id}/jacobwoffenden/upload"
  # }

  # home_directory_mappings {
  #   entry  = "/download"
  #   target = "/${module.landing_bucket.s3_bucket_id}/jacobwoffenden/download"
  # }

  # This works
  home_directory = "/${module.landing_bucket.s3_bucket_id}/jacobwoffenden" # TODO: do we need an SFTP specific landing bucket?

  # TODO: Tagging
}

resource "aws_transfer_ssh_key" "jacobwoffenden" {
  server_id = aws_transfer_server.this.id
  user_name = aws_transfer_user.jacobwoffenden.user_name
  body      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+3qaLVtn6Pd+DasWHhIOBoXEEhF9GZAG+DYfJBeySS Ministry of Justice"
}

