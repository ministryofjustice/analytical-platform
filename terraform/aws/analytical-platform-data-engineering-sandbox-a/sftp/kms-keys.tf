module "s3_landing_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  aliases               = ["s3/landing"]
  description           = "Family SFTP Server, Landing S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_processed_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  aliases               = ["s3/processed"]
  description           = "Ingestion Scanning ClamAV S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_quarantine_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  aliases               = ["s3/quarantine"]
  description           = "Family SFTP Server, Quarantine S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_definitions_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  aliases               = ["s3/definitions"]
  description           = "Ingestion Scanning ClamAV S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}
