#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "mojap_national_security_data_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.15.1"

  bucket = "mojap-data-production-national-security-data"

  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mojap_national_security_data_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}


data "aws_iam_policy_document" "s3_server_access_logs_eu_west_2_policy" {
  #checkov:skip=CKV_AWS_356:resource "*" limited by condition
  statement {
    sid       = "S3ServerAccessLogsPolicy"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::moj-analytics-s3-logs/*"]
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.session.account_id]
    }
  }
}

module "moj_analytics_logs_bucket_eu_west_2" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.13.0"

  bucket = "moj-analytics-s3-logs"

  force_destroy = false

  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_server_access_logs_eu_west_2_policy.json

  object_lock_enabled = false

  versioning = {
    status = "Disabled"
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mojap_national_security_data_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = merge(
    var.tags,
    { "backup" = "false" }
  )
}
