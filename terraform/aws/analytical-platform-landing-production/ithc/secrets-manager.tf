module "secrets_manager" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.1.2"

  # Secret
  name_prefix             = "ithc-name-store"
  description             = "Holder for ITHC Consultants email addresses"
  recovery_window_in_days = 30

  # Policy
  create_policy       = true
  block_public_policy = true
  policy_statements = {
    read = {
      sid = "AllowAccountRead"
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-landing-production"]}:root"]
      }]
      actions = [
        "secretsmanager:*"
      ]
      resources = ["*"]
    }
  }

  ignore_secret_changes = true
  secret_string = jsonencode({
    content = "PLACEHOLDER"
  })

  tags = var.tags
}
