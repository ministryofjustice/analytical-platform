module "sns_topic" {
  source = "terraform-aws-modules/sns/aws"

  name              = "ingestion-notifications"
  display_name      = "ingestion-notifications"
  signature_version = 2

  kms_master_key_id = module.sns_kms.key_id
}
