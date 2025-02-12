locals {
  environment_configurations = {
    production = {
      datasync_opg_replication_iam_role_arn = "arn:aws:iam::471112983409:role/datasync-replication"
      datasync_opg_source_bucket_arn        = "arn:aws:s3:::mojap-ingestion-production-datasync-opg"
      datasync_opg_replication_kms_key_arn  = "arn:aws:kms:eu-west-2:471112983409:key/db1f2938-3fc6-45a7-8744-095a72c78f9b" #gitleaks:allow
    }
  }
}
