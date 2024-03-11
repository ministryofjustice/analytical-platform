module "definition_upload_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  publish        = true
  create_package = false

  function_name = "ingestion-definition-upload"
  description   = ""
  package_type  = "Image"
  memory_size   = 2048
  timeout       = 900
  image_uri     = "684969100054.dkr.ecr.eu-west-2.amazonaws.com/analytical-platform-family-transfer-server:python-27" # TODO: Remove hardcoding and use data source

  environment_variables = {
    MODE                         = "definition-upload",
    CLAMAV_DEFINITON_BUCKET_NAME = "${module.definitions_bucket.s3_bucket_id}"
  }

  attach_policy_statements = true
  policy_statements = {
    kms_access = {
      sid    = "AllowKMS"
      effect = "Allow"
      actions = [
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt"
      ]
      resources = [module.s3_definitions_kms.key_arn]
    },
    s3_access = {
      sid    = "AllowS3"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["arn:aws:s3:::${module.definitions_bucket.s3_bucket_id}/*"]
    }
  }

  allowed_triggers = {
    "eventbridge" = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.ingestion_scanning_definition_update.arn
    }
  }
}

module "scan_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  publish        = true
  create_package = false

  function_name          = "ingestion-scan"
  description            = ""
  package_type           = "Image"
  memory_size            = 2048
  ephemeral_storage_size = 10240
  timeout                = 900
  image_uri              = "684969100054.dkr.ecr.eu-west-2.amazonaws.com/analytical-platform-family-transfer-server:pythonjw-5" # TODO: Remove hardcoding and use data source

  environment_variables = {
    MODE                         = "scan",
    CLAMAV_DEFINITON_BUCKET_NAME = module.definitions_bucket.s3_bucket_id
    LANDING_BUCKET_NAME          = module.landing_bucket.s3_bucket_id
    QUARANTINE_BUCKET_NAME       = module.quarantine_bucket.s3_bucket_id
    PROCESSED_BUCKET_NAME        = module.processed_bucket.s3_bucket_id
    SNS_TOPIC_ARN                = module.sns_topic.topic_arn
  }

  attach_policy_statements = true
  policy_statements = {
    kms_access = {
      sid    = "AllowKMS"
      effect = "Allow"
      actions = [
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt"
      ]
      resources = [
        module.s3_definitions_kms.key_arn,
        module.s3_landing_kms.key_arn,
        module.s3_quarantine_kms.key_arn,
        module.s3_processed_kms.key_arn,
        module.sns_kms.key_arn
      ]
    },
    s3_access = {
      sid    = "AllowS3"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:CopyObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:PutObjectTagging"
      ]
      resources = [
        "arn:aws:s3:::${module.definitions_bucket.s3_bucket_id}/*",
        "arn:aws:s3:::${module.landing_bucket.s3_bucket_id}/*",
        "arn:aws:s3:::${module.quarantine_bucket.s3_bucket_id}/*",
        "arn:aws:s3:::${module.processed_bucket.s3_bucket_id}/*"
      ]
    },
    sns_access = {
      sid    = "AllowSNS"
      effect = "Allow"
      actions = [
        "sns:Publish"
      ]
      resources = [module.sns_topic.topic_arn]
    }
  }

  allowed_triggers = {
    "s3" = {
      principal  = "s3.amazonaws.com"
      source_arn = module.landing_bucket.s3_bucket_arn
    }
  }
}

module "notify_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  publish        = true
  create_package = false

  function_name          = "ingestion-notify"
  description            = ""
  package_type           = "Image"
  memory_size            = 2048
  ephemeral_storage_size = 10240
  timeout                = 900
  image_uri              = "684969100054.dkr.ecr.eu-west-2.amazonaws.com/analytical-platform-notify:4" # TODO: Remove hardcoding and use data source

  environment_variables = {
    CLAMAV_DEFINITON_BUCKET_NAME = module.definitions_bucket.s3_bucket_id
    LANDING_BUCKET_NAME          = module.landing_bucket.s3_bucket_id
    QUARANTINE_BUCKET_NAME       = module.quarantine_bucket.s3_bucket_id
    PROCESSED_BUCKET_NAME        = module.processed_bucket.s3_bucket_id
    SNS_TOPIC_ARN                = module.sns_topic.topic_arn
  }

  # TODO: Check if KMS key is actually needed below
  attach_policy_statements = true
  policy_statements = {
    kms_access = {
      sid    = "AllowKMS"
      effect = "Allow"
      actions = [
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt"
      ]
      resources = [
        module.sns_kms.key_arn
      ]
    },
    sns_access = {
      sid    = "AllowSNS"
      effect = "Allow"
      actions = [
        "sns:Publish"
      ]
      resources = [module.sns_topic.topic_arn]
    }
  }

  allowed_triggers = {
    "sns" = {
      principal  = "sns.amazonaws.com"
      source_arn = module.sns_topic.topic_arn
    }
  }
}
