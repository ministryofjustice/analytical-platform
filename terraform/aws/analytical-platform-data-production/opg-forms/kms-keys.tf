module "opg_forms_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

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
