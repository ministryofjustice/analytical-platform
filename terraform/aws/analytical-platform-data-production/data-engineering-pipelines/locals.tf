locals {

  protected_dbs = [
    {
      name                    = "xhibit"
      database_string_pattern = ["xhibit_*"]
      role_names_to_exempt = [
        "courts-data-engineer",
        "airflow_prod_xhibit_etl",
        "airflow_dev_xhibit_etl_athena",
        "restricted-admin",
        "create-a-derived-table"
      ]
    },
    {
      name = "mags"
      database_string_pattern = [
        "mags_curated_*",
        "mags_processed_*",
      ]
      role_names_to_exempt = [
        "courts-data-engineer",
        "airflow_prod_mags_data_processor",
        "restricted-admin",
        "airflow_dev_mags_data_processor",
      ]
    },
    {
      name                    = "familyman"
      database_string_pattern = ["familyman_*"]
      role_names_to_exempt = [
        "data-first-data-engineer",
        "airflow_family_ap",
        "restricted-admin",
        "alpha_user_lavmatt",
        "airflow_prod_familyman",
        "airflow_dev_familyman",
      ]
    },
    {
      name                    = "delius"
      database_string_pattern = ["delius*"]
      role_names_to_exempt = [
        "prison-probation-data-engineer",
        "data-engineering-infrastructure",
        "create-a-derived-table",
        "github-actions-infrastructure",
        "restricted-admin",
      ]
    },
    {
      name                    = "oasys"
      database_string_pattern = ["oasys*"]
      role_names_to_exempt = [
        "prison-probation-data-engineer",
        "data-engineering-infrastructure",
        "create-a-derived-table",
        "github-actions-infrastructure",
        "restricted-admin",
      ]
    },
    {
      name                    = "nomis"
      database_string_pattern = ["nomis*"]
      role_names_to_exempt = [
        "prison-probation-data-engineer",
        "airflow_prod_nomis_transform",
        "airflow_prod_nomis_ao",
        "airflow_prod_nomis_ao_legacy",
        "airflow_prod_nomis_derive",
        "airflow_dev_nomis_transform",
        "airflow_dev_nomis_ao",
        "airflow_dev_nomis_ao_legacy",
        "airflow_dev_nomis_derive",
        "restricted-admin",
        "create-a-derived-table"
      ]
    },
    {
      name                    = "pathfinder"
      database_string_pattern = ["pathfinder*"]
      role_names_to_exempt = [
        "prison-probation-data-engineer",
        "restricted-admin",
      ]
    },
    {
      name = "caseman"
      database_string_pattern = [
        "caseman_v*",
        "caseman_dev_v*",
        "caseman_derived_v*",
        "caseman_derived_dev_v*",
      ]
      role_names_to_exempt = [
        "restricted-admin",
        "cc-data-engineer",
        "data-first-data-engineer",
        "airflow_prod_civil",
        "airflow_dev_civil",
      ]
    },
    {
      name = "pcol"
      database_string_pattern = [
        "pcol_v*",
        "pcol_dev_v*",
        "pcol_derived_v*",
        "pcol_derived_dev_v*",
      ]
      role_names_to_exempt = [
        "restricted-admin",
        "cc-data-engineer",
        "data-first-data-engineer",
        "airflow_prod_civil",
        "airflow_dev_civil",
      ]
    }
  ]

  unique_role_names = distinct(flatten([for db in local.protected_dbs : db.role_names_to_exempt])) // to retrieve unique_ids

  data_engineering_buckets = {
    "alpha-data-engineer-logs" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "alpha-data-engineer-logs/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Effect    = "Deny"
              Principal = "*"
              Resource  = "arn:aws:s3:::alpha-data-engineer-logs"
              Sid       = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }
    "moj-analytics-lookup-tables" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "moj-analytics-lookup-tables/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
    }
    "moj-analytics-lookup-tables-dev" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "moj-analytics-lookup-tables-dev/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
    }

    "moj-analytics-lookup-tables-preprod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "moj-analytics-lookup-tables-preprod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }


    }

    "mojap-athena-query-dump" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = false,
        mfa_delete = false
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
        target_prefix = "mojap-athena-query-dump/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        abort_incomplete_multipart_upload_days = 7,
        enabled                                = true
        id                                     = "keep_3_days"
        expiration = {
          days = 3
        }
        },
        {
          abort_incomplete_multipart_upload_days = 1,
          enabled                                = true
          id                                     = "properly delete non current objects"

          expiration = {
            days                         = 0
            expired_object_delete_marker = true
          }

          noncurrent_version_expiration = {
            days = 1
          }
        }
      ]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:ListBucket",
                "s3:GetBucketLocation",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "AROA27HJSWAHEPTTLIWSO"
              }
              Resource = "arn:aws:s3:::mojap-athena-query-dump"
              Sid      = "list"
            },
            {
              Action = [
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectVersion",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion",
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:RestoreObject",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "AROA27HJSWAHEPTTLIWSO"
              }
              Resource = "arn:aws:s3:::mojap-athena-query-dump/*"
              Sid      = "readwrite"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-land" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-land/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = [
                  "arn:aws:iam::649098267436:role/glue-crawler-production",
                  "arn:aws:iam::649098267436:role/glue-job-production",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land/opg/sirius/*"
              Sid      = "WriteOnlyAccess-mojap-land-opg-sirius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = [
                  "arn:aws:iam::649098267436:role/glue-crawler-production",
                  "arn:aws:iam::649098267436:role/glue-job-production",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land/opg/sirius/*"
              Sid      = "112-mojap-land-opg-sirius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = [
                  "arn:aws:iam::649098267436:role/glue-crawler-production",
                  "arn:aws:iam::649098267436:role/glue-job-production",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land/opg/sirius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-opg-sirius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = [
                  "arn:aws:iam::649098267436:role/glue-crawler-production",
                  "arn:aws:iam::649098267436:role/glue-job-production",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land/opg/sirius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-opg-sirius"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::754256621582:role/cloud-platform-irsa-f18ffa578df06513-live"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/prisoner-money/*"
              Sid      = "WriteOnlyAccess-mojap-land-hmpps-prisoner-money"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::754256621582:role/cloud-platform-irsa-f18ffa578df06513-live"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/prisoner-money/*"
              Sid      = "112-mojap-land-hmpps-prisoner-money"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::754256621582:role/cloud-platform-irsa-f18ffa578df06513-live"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/prisoner-money/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-hmpps-prisoner-money"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::754256621582:role/cloud-platform-irsa-f18ffa578df06513-live"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/prisoner-money/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-hmpps-prisoner-money"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = [
                  "arn:aws:iam::754256621582:user/system/pathfinder-rds-to-s3-snapshots-user/pathfinder-rds-to-s3-snapshots-user-60c8aab9afd91b24",
                  "arn:aws:iam::754256621582:user/system/pathfinder-rds-to-s3-snapshots-user/pathfinder-rds-to-s3-snapshots-user-e50b6204edd91441",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/pathfinder/*"
              Sid      = "WriteOnlyAccess-mojap-land-hmpps-pathfinder"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = [
                  "arn:aws:iam::754256621582:user/system/pathfinder-rds-to-s3-snapshots-user/pathfinder-rds-to-s3-snapshots-user-60c8aab9afd91b24",
                  "arn:aws:iam::754256621582:user/system/pathfinder-rds-to-s3-snapshots-user/pathfinder-rds-to-s3-snapshots-user-e50b6204edd91441",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/pathfinder/*"
              Sid      = "112-mojap-land-hmpps-pathfinder"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = [
                  "arn:aws:iam::754256621582:user/system/pathfinder-rds-to-s3-snapshots-user/pathfinder-rds-to-s3-snapshots-user-60c8aab9afd91b24",
                  "arn:aws:iam::754256621582:user/system/pathfinder-rds-to-s3-snapshots-user/pathfinder-rds-to-s3-snapshots-user-e50b6204edd91441",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/pathfinder/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-hmpps-pathfinder"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = [
                  "arn:aws:iam::754256621582:user/system/pathfinder-rds-to-s3-snapshots-user/pathfinder-rds-to-s3-snapshots-user-60c8aab9afd91b24",
                  "arn:aws:iam::754256621582:user/system/pathfinder-rds-to-s3-snapshots-user/pathfinder-rds-to-s3-snapshots-user-e50b6204edd91441",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/pathfinder/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-hmpps-pathfinder"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
              }
              Resource = "arn:aws:s3:::mojap-land/ppas/*"
              Sid      = "WriteOnlyAccess-mojap-land-ppas"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
              }
              Resource = "arn:aws:s3:::mojap-land/ppas/*"
              Sid      = "112-mojap-land-ppas"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
              }
              Resource = "arn:aws:s3:::mojap-land/ppas/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-ppas"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
              }
              Resource = "arn:aws:s3:::mojap-land/ppas/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-ppas"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/delius/*"
              Sid      = "WriteDeleteAccess-mojap-land-hmpps-delius"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land"
              Sid      = "ListBucketObjects-mojap-land-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/delius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/delius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-hmpps-delius"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/oasys/*"
              Sid      = "WriteDeleteAccess-mojap-land-hmpps-oasys"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land"
              Sid      = "ListBucketObjects-mojap-land-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/oasys/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-hmpps-oasys"
            },
            {
              Action = [
                "s3:ListBucket",
                "s3:PutBucketNotification",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-land"
              Sid      = "AllowListBucket-mojap-land-hmpps-delius"
            },
            {
              Action = [
                "s3:DeleteObject",
                "s3:GetObject",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/delius/*"
              Sid      = "GetDeleteAccess-mojap-land-hmpps-delius"
            },
            {
              Action = [
                "s3:ListBucket",
                "s3:PutBucketNotification",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-land"
              Sid      = "AllowListBucket-mojap-land-hmpps-oasys"
            },
            {
              Action = [
                "s3:DeleteObject",
                "s3:GetObject",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-land/hmpps/oasys/*"
              Sid      = "GetDeleteAccess-mojap-land-hmpps-oasys"
            },
            {
              Sid    = "AllowAnalyticalPlatformIngestionService"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::471112983409:role/transfer"
              }
              Action = [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:PutObjectTagging",
                "s3:GetObjectAcl",
                "s3:PutObjectAcl"
              ]
              Resource = [
                "arn:aws:s3:::mojap-land",
                "arn:aws:s3:::mojap-land/bold/essex-police/*"
              ]
            },
            {
              Sid    = "ListBucketAccessElectronicMonitoringService"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::976799291502:role/send_table_to_ap"
              }
              Action = "s3:ListBucket"
              Resource = [
                "arn:aws:s3:::mojap-land",
              ]
            },
            {
              Sid    = "WriteOnlyAccessElectronicMonitoringService"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::976799291502:role/send_table_to_ap"
              }
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:PutObjectAcl"
              ]
              Resource = [
                "arn:aws:s3:::mojap-land/electronic_monitoring/load/*"
              ]
            }
          ]
          Version = "2012-10-17"
        }
      )
    }
    "mojap-land-dev" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-land-dev/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/hmpps/delius/*"
              Sid      = "WriteDeleteAccess-mojap-land-dev-hmpps-delius"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev"
              Sid      = "ListBucketObjects-mojap-land-dev"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/hmpps/delius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-dev-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/hmpps/delius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-dev-hmpps-delius"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/hmpps/oasys/*"
              Sid      = "WriteDeleteAccess-mojap-land-dev-hmpps-oasys"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev"
              Sid      = "ListBucketObjects-mojap-land-dev-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/hmpps/oasys/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-dev-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-dev-hmpps-oasys"
            },
            {
              Action = [
                "s3:ListBucket",
                "s3:PutBucketNotification",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev"
              Sid      = "AllowListBucket-mojap-land-dev-hmpps-delius"
            },
            {
              Action = [
                "s3:DeleteObject",
                "s3:GetObject",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/hmpps/delius/*"
              Sid      = "GetDeleteAccess-mojap-land-dev-hmpps-delius"
            },
            {
              Action = [
                "s3:ListBucket",
                "s3:PutBucketNotification",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev"
              Sid      = "AllowListBucket-mojap-land-dev-hmpps-oasys"
            },
            {
              Action = [
                "s3:DeleteObject",
                "s3:GetObject",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-dev"
              }
              Resource = "arn:aws:s3:::mojap-land-dev/hmpps/oasys/*"
              Sid      = "GetDeleteAccess-mojap-land-dev-hmpps-oasys"
            },
            {
              Sid    = "AllowAnalyticalPlatformIngestionService"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::730335344807:role/transfer"
              }
              Action = [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:PutObjectTagging",
                "s3:GetObjectAcl",
                "s3:PutObjectAcl"
              ]
              Resource = [
                "arn:aws:s3:::mojap-land-dev",
                "arn:aws:s3:::mojap-land-dev/bold/essex-police/*"
              ]
            },
            {
              Sid    = "ListBucketAccessElectronicMonitoringService"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::800964199911:role/send_table_to_ap"
              }
              Action = "s3:ListBucket"
              Resource = [
                "arn:aws:s3:::mojap-land-dev",
              ]
            },
            {
              Sid    = "WriteOnlyAccessElectronicMonitoringService"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::800964199911:role/send_table_to_ap"
              }
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:PutObjectAcl"
              ]
              Resource = [
                "arn:aws:s3:::mojap-land-dev",
                "arn:aws:s3:::mojap-land-dev/electronic_monitoring/load/*"
              ]
            }
          ]
          Version = "2012-10-17"
        }
      )
    }
    "mojap-land-fail-dev" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-land-fail-dev/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "AROASYCVJWSNN3REJ3AFS"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-dev/hmpps/delius/*"
              Sid      = "WriteOnlyAccess-mojap-land-fail-dev-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNN3REJ3AFS"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-dev/hmpps/delius/*"
              Sid      = "112-mojap-land-fail-dev-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNN3REJ3AFS"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-dev/hmpps/delius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-fail-dev-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNN3REJ3AFS"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-dev/hmpps/delius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-fail-dev-hmpps-delius"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "AROASYCVJWSNFCCBEO2AN"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-dev/hmpps/oasys/*"
              Sid      = "WriteOnlyAccess-mojap-land-fail-dev-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNFCCBEO2AN"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-dev/hmpps/oasys/*"
              Sid      = "112-mojap-land-fail-dev-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNFCCBEO2AN"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-dev/hmpps/oasys/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-fail-dev-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNFCCBEO2AN"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-dev/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-fail-dev-hmpps-oasys"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-land-fail-preprod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-land-fail-preprod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-preprod/hmpps/delius/*"
              Sid      = "WriteOnlyAccess-mojap-land-fail-preprod-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-preprod/hmpps/delius/*"
              Sid      = "112-mojap-land-fail-preprod-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-preprod/hmpps/delius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-fail-preprod-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-preprod/hmpps/delius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-fail-preprod-hmpps-delius"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-preprod/hmpps/oasys/*"
              Sid      = "WriteOnlyAccess-mojap-land-fail-preprod-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-preprod/hmpps/oasys/*"
              Sid      = "112-mojap-land-fail-preprod-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-preprod/hmpps/oasys/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-fail-preprod-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-fail-preprod/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-fail-preprod-hmpps-oasys"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-land-preprod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-land-preprod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/hmpps/delius/*"
              Sid      = "WriteDeleteAccess-mojap-land-preprod-hmpps-delius"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod"
              Sid      = "ListBucketObjects-mojap-land-preprod-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/hmpps/delius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-preprod-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/hmpps/delius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-preprod-hmpps-delius"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/hmpps/oasys/*"
              Sid      = "WriteDeleteAccess-mojap-land-preprod-hmpps-oasys"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod"
              Sid      = "ListBucketObjects-mojap-land-preprod-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/hmpps/oasys/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-preprod-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-dms-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-preprod-hmpps-oasys"
            },
            {
              Action = [
                "s3:ListBucket",
                "s3:PutBucketNotification",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod"
              Sid      = "AllowListBucket-mojap-land-preprod-hmpps-delius"
            },
            {
              Action = [
                "s3:DeleteObject",
                "s3:GetObject",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/hmpps/delius/*"
              Sid      = "GetDeleteAccess-mojap-land-preprod-hmpps-delius"
            },
            {
              Action = [
                "s3:ListBucket",
                "s3:PutBucketNotification",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod"
              Sid      = "AllowListBucket-mojap-land-preprod-hmpps-oasys"
            },
            {
              Action = [
                "s3:DeleteObject",
                "s3:GetObject",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/hmpps/oasys/*"
              Sid      = "GetDeleteAccess-mojap-land-preprod-hmpps-oasys"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-metadata-dev" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-metadata-dev/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:GetObject"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-dev"
              }
              Resource = "arn:aws:s3:::mojap-metadata-dev/delius/*"
              Sid      = "ReadOnlyAccess-mojap-metadata-dev-delius"
            },
            {
              Action = "s3:GetObject"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-dev"
              }
              Resource = "arn:aws:s3:::mojap-metadata-dev/oasys/*"
              Sid      = "ReadOnlyAccess-mojap-metadata-dev-oasys"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = [
                  "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-dev",
                  "AROASYCVJWSNN3REJ3AFS",
                ]
              }
              Resource = "arn:aws:s3:::mojap-metadata-dev"
              Sid      = "ListBucketAccess-mojap-metadata-dev"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::800964199911:role/send_metadata_to_ap"
              }
              Resource = "arn:aws:s3:::mojap-metadata-dev"
              Sid      = "ListAccess-mojap-metadata-dev-electronic-monitoring"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectAcl"
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::800964199911:role/send_metadata_to_ap"
              }
              Resource = "arn:aws:s3:::mojap-metadata-dev/electronic_monitoring/*"
              Sid      = "PutAccess-mojap-metadata-dev-electronic-monitoring"
            }
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-metadata-preprod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-metadata-preprod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:GetObject"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-metadata-preprod/delius/*"
              Sid      = "ReadOnlyAccess-mojap-metadata-preprod-delius"
            },
            {
              Action = "s3:GetObject"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-metadata-preprod/oasys/*"
              Sid      = "ReadOnlyAccess-mojap-metadata-preprod-oasys"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = [
                  "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod",
                  "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod",
                ]
              }
              Resource = "arn:aws:s3:::mojap-metadata-preprod"
              Sid      = "ListBucketAccess-mojap-metadata-preprod"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-metadata-prod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-metadata-prod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
      lifecycle_rule = [{
        id                                     = "rule0"
        abort_incomplete_multipart_upload_days = 14
        enabled                                = true

        expiration = {
          days                         = 0
          expired_object_delete_marker = true
        }

        noncurrent_version_expiration = {
          days = 14
        }
      }]

      policy = jsonencode(
        {
          Statement = [
            {
              Action = "s3:GetObject"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-metadata-prod/delius/*"
              Sid      = "ReadOnlyAccess-mojap-metadata-prod-delius"
            },
            {
              Action = "s3:GetObject"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-metadata-prod/oasys/*"
              Sid      = "ReadOnlyAccess-mojap-metadata-prod-oasys"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = [
                  "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-prod",
                  "arn:aws:iam::189157455002:role/delius-lambda-copy-object-prod",
                ]
              }
              Resource = "arn:aws:s3:::mojap-metadata-prod"
              Sid      = "ListBucketAccess-mojap-metadata-prod"
            },
            {
              Action = "s3:ListBucket"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::976799291502:role/send_metadata_to_ap"
              }
              Resource = "arn:aws:s3:::mojap-metadata-prod"
              Sid      = "ListAccess-mojap-metadata-prod-electronic-monitoring"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:PutObjectAcl"
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::976799291502:role/send_metadata_to_ap"
              }
              Resource = "arn:aws:s3:::mojap-metadata-prod/electronic_monitoring/*"
              Sid      = "PutAccess-mojap-metadata-prod-electronic-monitoring"
            }
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-raw-hist" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-raw-hist/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist/hmpps/delius/*"
              Sid      = "WriteOnlyAccess-mojap-raw-hist-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist/hmpps/delius/*"
              Sid      = "112-mojap-raw-hist-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist/hmpps/delius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-raw-hist-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist/hmpps/delius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-hmpps-delius"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist/hmpps/oasys/*"
              Sid      = "WriteOnlyAccess-mojap-raw-hist-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist/hmpps/oasys/*"
              Sid      = "112-mojap-raw-hist-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist/hmpps/oasys/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-raw-hist-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-prod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-hmpps-oasys"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }
    "mojap-raw-hist-dev" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-raw-hist-dev/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "AROASYCVJWSNN3REJ3AFS"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-dev/hmpps/delius/*"
              Sid      = "WriteOnlyAccess-mojap-raw-hist-dev-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNN3REJ3AFS"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-dev/hmpps/delius/*"
              Sid      = "112-mojap-raw-hist-dev-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNN3REJ3AFS"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-dev/hmpps/delius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-raw-hist-dev-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNN3REJ3AFS"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-dev/hmpps/delius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-dev-hmpps-delius"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "AROASYCVJWSNFCCBEO2AN"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-dev/hmpps/oasys/*"
              Sid      = "WriteOnlyAccess-mojap-raw-hist-dev-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNFCCBEO2AN"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-dev/hmpps/oasys/*"
              Sid      = "112-mojap-raw-hist-dev-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNFCCBEO2AN"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-dev/hmpps/oasys/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-raw-hist-dev-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "AROASYCVJWSNFCCBEO2AN"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-dev/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-dev-hmpps-oasys"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-raw-hist-preprod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-raw-hist-preprod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/delius/*"
              Sid      = "WriteOnlyAccess-mojap-raw-hist-preprod-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/delius/*"
              Sid      = "112-mojap-raw-hist-preprod-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/delius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-raw-hist-preprod-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/delius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-preprod-hmpps-delius"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/oasys/*"
              Sid      = "WriteOnlyAccess-mojap-raw-hist-preprod-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/oasys/*"
              Sid      = "112-mojap-raw-hist-preprod-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/oasys/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-raw-hist-preprod-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-preprod-hmpps-oasys"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

    "mojap-raw-hist-preprod" = {
      grant = [{
        id         = data.aws_canonical_user_id.current.id
        permission = "FULL_CONTROL",
        type       = "CanonicalUser"
      }]
      force_destroy       = false
      object_lock_enabled = false
      acl                 = "private"
      versioning = {
        enabled    = true,
        mfa_delete = false
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
        target_prefix = "mojap-raw-hist-preprod/"
      }
      public_access_block = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }

      policy = jsonencode(
        {
          Statement = [
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/delius/*"
              Sid      = "WriteOnlyAccess-mojap-raw-hist-preprod-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/delius/*"
              Sid      = "112-mojap-raw-hist-preprod-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/delius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-raw-hist-preprod-hmpps-delius"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/delius-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/delius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-preprod-hmpps-delius"
            },
            {
              Action = [
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/oasys/*"
              Sid      = "WriteOnlyAccess-mojap-raw-hist-preprod-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-acl" = "bucket-owner-full-control"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/oasys/*"
              Sid      = "112-mojap-raw-hist-preprod-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                StringNotEquals = {
                  "s3:x-amz-server-side-encryption" = "AES256"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/oasys/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-raw-hist-preprod-hmpps-oasys"
            },
            {
              Action = "s3:PutObject"
              Condition = {
                Null = {
                  "s3:x-amz-server-side-encryption" = "true"
                }
              }
              Effect = "Deny"
              Principal = {
                AWS = "arn:aws:iam::189157455002:role/oasys-lambda-copy-object-preprod"
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-preprod-hmpps-oasys"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }

  }
}
