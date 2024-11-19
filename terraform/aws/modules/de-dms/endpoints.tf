# DMS Source Endpoint
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "${var.db}-source-${var.region}-${var.environment}"
  endpoint_type = "source"
  engine_name   = "oracle"
  secrets_manager_arn = var.secrets_manager_arn

  #username      = var.source_database.username
  #password      = var.source_database.password
  #server_name   = var.source_database.server_name
  #port          = var.source_database.port
  #database_name = var.source_database.database_name
}

## DMS S3 Target Endpoint
#resource "aws_dms_s3_endpoint" "s3_target" {
#  endpoint_id             = "aws_dms_s3_endpoint-id-CHANGE-THIS!!"
#  endpoint_type           = "target"
#  bucket_name             = var.s3_bucket
#  service_access_role_arn = aws_iam_role.dms_vpc_role.arn
#}
#
