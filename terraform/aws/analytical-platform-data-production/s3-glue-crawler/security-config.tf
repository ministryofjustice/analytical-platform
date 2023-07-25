resource "aws_glue_security_configuration" "glue_security_config" {
  name = "vcms_data_security_config"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn = data.aws_kms_key.rds_s3_export.arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}
