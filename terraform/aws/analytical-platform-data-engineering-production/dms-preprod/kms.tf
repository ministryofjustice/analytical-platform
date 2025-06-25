module "dms_preprod_kms" {

  # Commit hash for v3.1.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms?ref=fe1beca2118c0cb528526e022a53381535bb93cd"

  aliases               = ["dms/dms-preprod"]
  description           = "Used in the HMPPS probation domain to encode secrets and traffic"
  enable_default_policy = true

  grants = {
    allow_dms = {
      to_principal = {
        service = "dms.amazonaws.com"
      }
      operations = [
        "kms:GenerateDataKey*",
        "kms:Decrypt"
      ]
    }
  }

  deletion_window_in_days = 7

  tags = var.tags
}
