module "dms_dev_kms" {

  # Commit hash for v3.1.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms?ref=fe1beca2118c0cb528526e022a53381535bb93cd"

  aliases               = ["dms/dms-dev"]
  description           = "Used in the HMPPS probation domain to encode secrets and traffic"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = var.tags
}
