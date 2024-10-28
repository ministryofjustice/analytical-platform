locals {
  cadet_buckets = {
    "mojap-derived-tables" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        status = "Disabled"
      }
      mfa_delete = false
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
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }

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

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
              }
              Resource = [
                "arn:aws:s3:::mojap-derived-tables/dev/models/domain_name=*/*",
                "arn:aws:s3:::mojap-derived-tables/dev/run_artefacts/*",
                "arn:aws:s3:::mojap-derived-tables/seeds/*",
                "arn:aws:s3:::mojap-derived-tables/dev/seeds/*",
              ]
              Sid = "AllowCompliantPaths"
            },
            {
              Action = [
                "s3:ListBucket",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
              }
              Resource = [
                "arn:aws:s3:::mojap-derived-tables",
              ]
              Sid = "AllowList"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }
  }
}
