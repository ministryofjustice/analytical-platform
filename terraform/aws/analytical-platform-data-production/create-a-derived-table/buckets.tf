module "mojap_cadet_production" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.1"

  bucket = "mojap-derived-tables"
  grant = [{
    id         = data.aws_canonical_user_id.current.id
    permission = "FULL_CONTROL",
    type       = "CanonicalUser"
  }]
  force_destroy       = false
  object_lock_enabled = false
  acl                 = "private"
  versioning = {
    status     = "Disabled"
    mfa_delete = false
  }
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = false

      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  logging = {
    target_bucket = "moj-analytics-s3-logs"
    target_prefix = "mojap-derived-tables/"
  }

  attach_public_policy    = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle_rule = [
    {
      enabled = true
      id      = "dev/models"

      filter = {
        prefix = "dev/models/"
      }

      expiration = {
        days                         = 10
        expired_object_delete_marker = false
      }
    },
    {
      enabled = true
      id      = "dev/seeds"

      filter = {
        prefix = "dev/seeds/"
      }

      expiration = {
        days                         = 10
        expired_object_delete_marker = false
      }
    },
    {
      enabled = true
      id      = "dev/run_artefacts"

      filter = {
        prefix = "dev/run_artefacts/"
      }

      expiration = {
        days                         = 3
        expired_object_delete_marker = false
      }
    },
    {
      enabled = true
      id      = "prod/run_artefacts"

      filter = {
        prefix = "prod/run_artefacts/"
      }

      expiration = {
        days                         = 14
        expired_object_delete_marker = false
      }
    },
    {
      enabled = true
      id      = "sandpit/models"

      filter = {
        prefix = "sandpit/models/"
      }

      expiration = {
        days                         = 3
        expired_object_delete_marker = false
      }
    }
  ]

  attach_policy = true
  policy        = data.aws_iam_policy_document.mojap_cadet_production.json

  replication_configuration = data.aws_s3_bucket_replication_configuration.mojap_cadet_to_apc_compute

  tags = var.tags
}

data "aws_iam_policy_document" "mojap_cadet_production" {
  statement {
    sid    = "AllowCompliantPaths"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::mojap-derived-tables/dev/models/domain_name=*/*",
      "arn:aws:s3:::mojap-derived-tables/dev/run_artefacts/*",
      "arn:aws:s3:::mojap-derived-tables/seeds/*",
      "arn:aws:s3:::mojap-derived-tables/dev/seeds/*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowList"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::mojap-derived-tables",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

data "aws_s3_bucket_replication_configuration" "mojap_cadet_to_apc_compute" {
  role = module.mojap_cadet_production_replication_iam_role.iam_role_arn

  rules = [
    {
      id                        = "mojap-data-production-cadet-to-apc-production"
      status                    = "Enabled"
      delete_marker_replication = true

      # source_selection_criteria = {
      #   sse_kms_encrypted_objects = {
      #     enabled = true
      #   }
      # }

      destination = {
        account_id    = var.account_ids["analytical-platform-compute-production"]
        bucket        = "arn:aws:s3:::mojap-compute-production-derived-tables-replication"
        storage_class = "STANDARD"
        access_control_translation = {
          owner = "Destination"
        }
        encryption_configuration = {
          replica_kms_key_id = "arn:aws:kms:eu-west-2:${var.account_ids["analytical-platform-compute-production"]}:key/${local.mojap_apc_prod_cadet_replication_kms_key_id}"
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
