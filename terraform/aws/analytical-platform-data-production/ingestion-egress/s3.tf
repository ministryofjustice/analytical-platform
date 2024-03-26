
module "development_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"

  bucket        = "mojap-data-production-bold-egress-development"
  force_destroy = true

  versioning = {
    enabled = true
  }

  replication_configuration = {
    role = module.development_replication_iam_role.iam_role_arn
    rules = [
      {
        id                        = "mojap-ingestion-development-bold-egress"
        status                    = "Enabled"
        delete_marker_replication = false

        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }

        destination = {
          account_id    = "730335344807"
          bucket        = "arn:aws:s3:::mojap-ingestion-development-bold-egress"
          storage_class = "STANDARD"
          access_control_translation = {
            owner = "Destination"
          }
          encryption_configuration = {
            replica_kms_key_id = "arn:aws:kms:eu-west-2:730335344807:key/9b5b6691-d0c0-40b4-9bc4-7117878712ae"
          }
          metrics = {
            status  = "Enabled"
            minutes = 15
          }
          replication_time = {
            status  = "Enabled"
            minutes = 15
          }
        }
      }
    ]
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.development_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}


module "production_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"

  bucket        = "mojap-data-production-bold-egress-production"
  force_destroy = true

  versioning = {
    enabled = true
  }

  replication_configuration = {
    role = module.production_replication_iam_role.iam_role_arn
    rules = [
      {
        id                        = "mojap-ingestion-production-bold-egress"
        status                    = "Enabled"
        delete_marker_replication = false

        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }

        destination = {
          account_id    = "471112983409"
          bucket        = "arn:aws:s3:::mojap-ingestion-production-bold-egress"
          storage_class = "STANDARD"
          access_control_translation = {
            owner = "Destination"
          }
          encryption_configuration = {
            replica_kms_key_id = "arn:aws:kms:eu-west-2:471112983409:key/159671dd-57fa-497c-93b9-2aa9aa8b0fd1"
          }
          metrics = {
            status  = "Enabled"
            minutes = 15
          }
          replication_time = {
            status  = "Enabled"
            minutes = 15
          }
        }
      }
    ]
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.development_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
