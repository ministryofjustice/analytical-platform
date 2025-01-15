
# DMS Source Endpoint
resource "aws_dms_endpoint" "source_endpoint" {
  endpoint_id   = "source-endpoint-id-CHANGE-THIS!!"
  endpoint_type = "source"
  engine_name   = "db-CHANGE-THIS!!"
  username      = var.source_database.username
  password      = var.source_database.password
  server_name   = var.source_database.server_name
  port          = var.source_database.port
  database_name = var.source_database.database_name
}

# DMS S3 Target Endpoint
resource "aws_dms_s3_endpoint" "s3_target_endpoint" {
  endpoint_id             = "aws_dms_s3_endpoint-id-CHANGE-THIS!!"
  endpoint_type           = "target"
  bucket_name             = var.s3_bucket
  service_access_role_arn = aws_iam_role.dms_vpc_role.arn
}

# DMS Replication Subnet Group
resource "aws_dms_replication_subnet_group" "replication_subnet_group" {
  replication_subnet_group_id          = "dms-subnet-group-id-CHANGE-THIS!!"
  replication_subnet_group_description = "Subnet group for DMS replication instances"
  subnet_ids                           = var.subnet_ids
}

# DMS Replication Instance
resource "aws_dms_replication_instance" "replication_instance" {
  replication_instance_id     = "dms-replication-instance"
  replication_instance_class  = var.replication_instance_class
  replication_subnet_group_id = aws_dms_replication_subnet_group.replication_subnet_group.id
  publicly_accessible         = false
}

# DMS Replication Task
resource "aws_dms_replication_task" "replication_task" {
  replication_task_id      = "replication_task-id-CHANGE-THIS!!"
  table_mappings           = "????"
  migration_type           = "full-load-and-cdc" # Adjust as necessary
  replication_instance_arn = aws_dms_replication_instance.replication_instance.arn
  source_endpoint_arn      = aws_dms_endpoint.source_endpoint.arn
  target_endpoint_arn      = aws_dms_s3_endpoint.s3_target_endpoint.arn
}
