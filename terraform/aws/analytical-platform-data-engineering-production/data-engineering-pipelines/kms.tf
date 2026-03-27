module "ae_download_athena_csv_kms" {

  # Commit hash for v4.2.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms?ref=407e3db34a65b384c20ef718f55d9ceacb97a846"

  aliases               = ["kms/ae_download_athena_csv"]
  description           = "A encryption KMS key for ae_download_athena_csv events"
  enable_default_policy = true

  key_statements = [
    {
      sid    = "AllowServiceAccess"
      effect = "Allow"
      actions = [
        "kms:Decrypt*",
        "kms:GenerateDataKey*",
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com", "sns.amazonaws.com"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}
