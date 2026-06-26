output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "aurora_cluster_endpoint" {
  description = "The endpoint of the Aurora PostgreSQL cluster"
  value       = module.aurora.cluster_endpoint
}

output "aurora_cluster_reader_endpoint" {
  description = "The reader endpoint of the Aurora PostgreSQL cluster"
  value       = module.aurora.cluster_reader_endpoint
}

output "aurora_cluster_port" {
  description = "The port of the Aurora PostgreSQL cluster"
  value       = module.aurora.cluster_port
}

output "aurora_master_secret_arn" {
  description = "The ARN of the master user secret (retrieve from Secrets Manager)"
  value       = module.aurora.master_user_secret_arn
}

# -----------------------------------------------------------------------------
# Redshift Outputs
# -----------------------------------------------------------------------------
output "redshift_endpoint_address" {
  description = "The DNS address for the Redshift Serverless instance"
  value       = module.redshift.endpoint_address
}

output "redshift_endpoint_port" {
  description = "The port that Redshift Serverless listens on"
  value       = module.redshift.endpoint_port
}

output "redshift_admin_secret_arn" {
  description = "The ARN of the Redshift admin user secret (retrieve from Secrets Manager)"
  value       = module.redshift.admin_secret_arn
}
