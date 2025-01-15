data "aws_region" "current" {}

data "aws_secretsmanager_secret_version" "source" {
  secret_id = var.source_secrets_manager_arn
}

# DMS Source Endpoint
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "${var.db}-source-${data.aws_region.current.name}-${var.environment}"
  endpoint_type = "source"
  engine_name   = "oracle"

  username      = jsondecode(data.aws_secretsmanager_secret_version.source.secret_string)["username"]
  password      = jsondecode(data.aws_secretsmanager_secret_version.source.secret_string)["password"]
  server_name   = var.dms_source_server_name
  port          = var.dms_source_server_port
  database_name = var.dms_source_database_name

  tags = {
    Name = "${var.db}-source-${data.aws_region.current.name}-${var.environment}"
  }

  lifecycle {
    ignore_changes = [
      # Prevent terraform from updating existing password stored in DMS endpoint
      password
    ]
  }
}

# DMS S3 Target Endpoint
resource "aws_dms_s3_endpoint" "s3_target" {
  endpoint_id   = "${var.db}-target-${data.aws_region.current.name}-${var.environment}"
  endpoint_type = "target"
  bucket_name   = var.landing_bucket
  bucket_folder = var.landing_bucket_folder
  #service_access_role_arn = aws_iam_role.dms.arn
  add_column_name                  = true
  canned_acl_for_objects           = "bucket-owner-full-control"
  cdc_max_batch_interval           = 3600
  cdc_min_file_size                = 32000
  compression_type                 = "GZIP"
  data_format                      = "parquet"
  encoding_type                    = "rle-dictionary"
  encryption_mode                  = "SSE_S3"
  include_op_for_full_load         = true
  parquet_timestamp_in_millisecond = true
  parquet_version                  = "parquet-2-0"
  timestamp_column_name            = "EXTRACTION_TIMESTAMP"
  service_access_role_arn          = "arn:aws:iam::684969100054:role/oracle19-dms-sandbox"

  tags = {
    Name = "${var.db}-target-${data.aws_region.current.name}-${var.environment}"
  }
}

output "secret_user" {
  value = jsondecode(data.aws_secretsmanager_secret_version.source.secret_string)["username"]
}
