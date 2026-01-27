locals {

  protected_dbs = [
    {
      name                    = "xhibit"
      database_string_pattern = ["xhibit", "xhibit_derived"]
      role_names_to_exempt = [
        "create-a-derived-table",
        "airflow_prod_cadet_deploy_xhibit"
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
        "airflow-test-hmcts-familyman-extraction",
        "airflow-production-hmcts-familyman-extraction"
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
        "data-engineering-probation-glue"
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
        "data-engineering-probation-glue"
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
        "create-a-derived-table",
        "airflow-production-analytical-platform-cadet-nomis-daily"
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
        "airflow_dev_civil",
        "airflow-test-hmcts-pcol",
        "airflow-production-hmcts-pcol-extraction"
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
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-athena-query-dump/*",
                "arn:aws:s3:::mojap-athena-query-dump"
              ]
              Sid = "DenyInsecureTransport"
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
                "arn:aws:s3:::mojap-land/bold/essex-police/*",
                "arn:aws:s3:::mojap-land/sscl/sscl_data_dump/*",
                "arn:aws:s3:::mojap-land/cps/*",
                "arn:aws:s3:::mojap-land/property/planetfm/backupfiles/*",
                "arn:aws:s3:::mojap-land/opg/prod/ocr/*",
                "arn:aws:s3:::mojap-land/corporate/epm/*"
              ]
            },
            {
              Sid    = "AllowAnalyticalPlatformIngestionDataSyncReplication"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::471112983409:role/datasync-replication"
              }
              Action = [
                "s3:ReplicateObject",
                "s3:ObjectOwnerOverrideToBucketOwner",
                "s3:GetObjectVersionTagging",
                "s3:ReplicateTags",
                "s3:ReplicateDelete"
              ]
              Resource = [
                "arn:aws:s3:::mojap-land/*"
              ]
            },
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-land/*",
                "arn:aws:s3:::mojap-land"
              ]
              Sid = "DenyInsecureTransport"
            },
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
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = [
                  "arn:aws:iam::288342028542:role/glue-job-integration",
                  "arn:aws:iam::288342028542:role/glue-job-dev",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land-dev/opg/sirius/*"
              Sid      = "WriteOnlyAccess-mojap-land-dev-opg-sirius"
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
                  "arn:aws:iam::288342028542:role/glue-job-integration",
                  "arn:aws:iam::288342028542:role/glue-job-dev",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land-dev/opg/sirius/*"
              Sid      = "112-mojap-land-dev-opg-sirius"
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
                  "arn:aws:iam::288342028542:role/glue-job-integration",
                  "arn:aws:iam::288342028542:role/glue-job-dev",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land-dev/opg/sirius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-dev-opg-sirius"
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
                  "arn:aws:iam::288342028542:role/glue-job-integration",
                  "arn:aws:iam::288342028542:role/glue-job-dev",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land-dev/opg/sirius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-dev-opg-sirius"
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
                "arn:aws:s3:::mojap-land-dev/analytical-platform/*",
                "arn:aws:s3:::mojap-land-dev/bold/essex-police/*",
                "arn:aws:s3:::mojap-land-dev/sscl/sscl_data_dump/*",
                "arn:aws:s3:::mojap-land-dev/cps/*",
                "arn:aws:s3:::mojap-land-dev/opg/dev/ocr/*",
                "arn:aws:s3:::mojap-land-dev/laa/dev/maatxhibit/*"
              ]
            },
            {
              Sid    = "AllowAnalyticalPlatformIngestionDataSyncReplication"
              Effect = "Allow"
              Principal = {
                AWS = "arn:aws:iam::730335344807:role/datasync-replication"
              }
              Action = [
                "s3:ReplicateObject",
                "s3:ObjectOwnerOverrideToBucketOwner",
                "s3:GetObjectVersionTagging",
                "s3:ReplicateTags",
                "s3:ReplicateDelete"
              ]
              Resource = [
                "arn:aws:s3:::mojap-land-dev/*"
              ]
            },
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-land-dev/*",
                "arn:aws:s3:::mojap-land-dev"
              ]
              Sid = "DenyInsecureTransport"
            },
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
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-land-fail-dev/*",
                "arn:aws:s3:::mojap-land-fail-dev"
              ]
              Sid = "DenyInsecureTransport"
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
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-land-fail-preprod/*",
                "arn:aws:s3:::mojap-land-fail-preprod"
              ]
              Sid = "DenyInsecureTransport"
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
                "s3:ListMultipartUploadParts",
              ]
              Effect = "Allow"
              Principal = {
                AWS = [
                  "arn:aws:iam::492687888235:role/glue-job-preproduction",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/opg/sirius/*"
              Sid      = "WriteOnlyAccess-mojap-land-preprod-opg-sirius"
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
                  "arn:aws:iam::492687888235:role/glue-job-preproduction",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/opg/sirius/*"
              Sid      = "112-mojap-land-preprod-opg-sirius"
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
                  "arn:aws:iam::492687888235:role/glue-job-preproduction",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/opg/sirius/*"
              Sid      = "DenyIncorrectEncryptionHeader-mojap-land-preprod-opg-sirius"
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
                  "arn:aws:iam::492687888235:role/glue-job-preproduction",
                ]
              }
              Resource = "arn:aws:s3:::mojap-land-preprod/opg/sirius/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-land-preprod-opg-sirius"
            },
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-land-preprod/*",
                "arn:aws:s3:::mojap-land-preprod"
              ]
              Sid = "DenyInsecureTransport"
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
      force_destroy       = true
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
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-metadata-dev/*",
                "arn:aws:s3:::mojap-metadata-dev"
              ]
              Sid = "DenyInsecureTransport"
            },
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
      force_destroy       = true
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
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-metadata-preprod/*",
                "arn:aws:s3:::mojap-metadata-preprod"
              ]
              Sid = "DenyInsecureTransport"
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
      force_destroy       = true
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
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-metadata-prod/*",
                "arn:aws:s3:::mojap-metadata-prod"
              ]
              Sid = "DenyInsecureTransport"
            },
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
                AWS = ["arn:aws:iam::189157455002:role/delius-prod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/delius-prod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/delius-prod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/delius-prod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-prod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-prod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-prod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-prod-validation"]
              }
              Resource = "arn:aws:s3:::mojap-raw-hist/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-hmpps-oasys"
            },
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-raw-hist/*",
                "arn:aws:s3:::mojap-raw-hist"
              ]
              Sid = "DenyInsecureTransport"
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
                AWS = ["arn:aws:iam::189157455002:role/delius-dev-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/delius-dev-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/delius-dev-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/delius-dev-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-dev-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-dev-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-dev-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-dev-validation"]
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-dev/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-dev-hmpps-oasys"
            },
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-raw-hist-dev/*",
                "arn:aws:s3:::mojap-raw-hist-dev"
              ]
              Sid = "DenyInsecureTransport"
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
                AWS = ["arn:aws:iam::189157455002:role/delius-preprod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/delius-preprod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/delius-preprod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/delius-preprod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-preprod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-preprod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-preprod-validation"]
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
                AWS = ["arn:aws:iam::189157455002:role/oasys-preprod-validation"]
              }
              Resource = "arn:aws:s3:::mojap-raw-hist-preprod/hmpps/oasys/*"
              Sid      = "DenyUnEncryptedObjectUploads-mojap-raw-hist-preprod-hmpps-oasys"
            },
            {
              Action = "s3:*"
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
              Principal = "*"
              Effect    = "Deny"
              Resource = [
                "arn:aws:s3:::mojap-raw-hist-preprod/*",
                "arn:aws:s3:::mojap-raw-hist-preprod"
              ]
              Sid = "DenyInsecureTransport"
            },
          ]
          Version = "2012-10-17"
        }
      )
    }
  }
}
