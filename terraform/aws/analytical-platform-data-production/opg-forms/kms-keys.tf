module "opg_forms_kms" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=af1d45558a6073c017a732d2273efcc733b34d0f" # v4.2.1

  aliases               = ["s3/mojap-data-production-opg-forms"]
  description           = "MoJ AP OPG Forms"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowGOVUKFormsAccess"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::443944947292:root"]
        }
      ]
      conditions = [{
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = ["arn:aws:iam::443944947292:role/govuk-forms-submissions-to-s3-production"]
      }]
    }
  ]
  deletion_window_in_days = 7
}
