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
}

## DMS S3 Target Endpoint
#resource "aws_dms_s3_endpoint" "s3_target" {
#  endpoint_id             = "aws_dms_s3_endpoint-id-CHANGE-THIS!!"
#  endpoint_type           = "target"
#  bucket_name             = var.s3_bucket
#  service_access_role_arn = aws_iam_role.dms_vpc_role.arn
#}
#
