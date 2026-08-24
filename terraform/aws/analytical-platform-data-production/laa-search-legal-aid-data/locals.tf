locals {
  app           = jsondecode(file("${path.module}/application_variables.json"))
  kms_key_users = jsondecode(file("${path.module}/kms_key_users.json"))

  splink_s3_key_user_arns = [
    for role in local.kms_key_users.splink_s3_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  splink_s3_test_key_user_arns = [
    for role in local.kms_key_users.splink_s3_test_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  splink_s3_input_write_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_input_write_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  splink_s3_input_read_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_input_read_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_output_write_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_output_write_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  splink_s3_output_read_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_output_read_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  splink_s3_audit_write_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_audit_write_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  splink_s3_audit_read_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_audit_read_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  application_name                 = local.app.application_name
  splink_search_input_bucket_name  = local.app.splink_search_input_bucket_name
  splink_search_output_bucket_name = local.app.splink_search_output_bucket_name
  splink_source_input_bucket_name  = local.app.splink_source_input_bucket_name
  splink_source_output_bucket_name = local.app.splink_source_output_bucket_name
  splink_audit_bucket_name         = local.app.splink_audit_bucket_name
  logging_bucket_name              = local.app.logging_bucket_name
  splink_bucket_name               = local.app.splink_bucket_name
  splink_test_bucket_name          = local.app.splink_test_bucket_name
  splink_test_sns_topic_name       = "splink-s3-event-notification-topic-test"
  splink_test_event_rule_name      = "splink-bucket-event-rule-test"
  bucket_access_policy_statements = {
    (local.splink_search_input_bucket_name) = [
      {
        Sid       = "WriteAccessBucketObjects"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_search_input_bucket_name}/*"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_input_write_bucket_key_user_arns
          }
        }
      },
      {
        Sid       = "ReadOnlyBucketObjects"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_search_input_bucket_name}/*"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_input_read_bucket_key_user_arns
          }
        }
      },
      {
        Sid       = "ReadOnlyBucketListing"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:ListBucket"]
        Resource  = "arn:aws:s3:::${local.splink_search_input_bucket_name}"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_input_read_bucket_key_user_arns
          }
        }
      }
    ]
    (local.splink_source_input_bucket_name) = [
      {
        Sid       = "WriteAccessBucketObjects"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_source_input_bucket_name}/*"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_input_write_bucket_key_user_arns
          }
        }
      },
      {
        Sid       = "ReadonlyBucketObjects"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_source_input_bucket_name}/*"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_input_read_bucket_key_user_arns
          }
        }
      },
      {
        Sid       = "ReadonlyBucketListing"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:ListBucket"]
        Resource  = "arn:aws:s3:::${local.splink_source_input_bucket_name}"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_input_read_bucket_key_user_arns
          }
        }
      }
    ]
    (local.splink_search_output_bucket_name) = [
      {
        Sid       = "WriteAccessBucketObjects"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_search_output_bucket_name}/*"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_output_write_bucket_key_user_arns
          }
        }
      },
      {
        Sid       = "ReadAccessBucketObjects"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_search_output_bucket_name}/*"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_output_read_bucket_key_user_arns
          }
        }
      },
      {
        Sid       = "ReadAccessBucketListing"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:ListBucket"]
        Resource  = "arn:aws:s3:::${local.splink_search_output_bucket_name}"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_output_read_bucket_key_user_arns
          }
        }
      }
    ]
    (local.splink_source_output_bucket_name) = [
      {
        Sid       = "WriteOnlyBucketObjects"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_source_output_bucket_name}/*"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_output_write_bucket_key_user_arns
          }
        }
      },
      {
        Sid       = "ReadAccessBucketObjects"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_source_output_bucket_name}/*"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_output_read_bucket_key_user_arns
          }
        }
      },
      {
        Sid       = "ReadAccessBucketListing"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:ListBucket"]
        Resource  = "arn:aws:s3:::${local.splink_source_output_bucket_name}"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_output_read_bucket_key_user_arns
          }
        }
      }
    ]
    (local.splink_audit_bucket_name) = [
      {
        Sid       = "WriteOnlyBucketObjects"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_audit_bucket_name}/*"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_audit_write_bucket_key_user_arns
          }
        }
      },
      {
        Sid       = "ReadAccessBucketObjects"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_audit_bucket_name}/*"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_audit_read_bucket_key_user_arns
          }
        }
      },
      {
        Sid       = "ReadAccessBucketListing"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:ListBucket"]
        Resource  = "arn:aws:s3:::${local.splink_audit_bucket_name}"
        Condition = {
          ArnNotEquals = {
            "aws:PrincipalArn" = local.splink_s3_audit_read_bucket_key_user_arns
          }
        }
      }
    ]
  }
  tags = local.app.tags
  test_tags = merge(
    local.tags,
    {
      Environment = "test"
    }
  )
}
