output "cluster_endpoint" {
  description = "The endpoint of the Aurora cluster"
  value       = module.aurora.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "The reader endpoint of the Aurora cluster"
  value       = module.aurora.cluster_reader_endpoint
}

output "cluster_port" {
  description = "The port of the Aurora cluster"
  value       = module.aurora.cluster_port
}

output "cluster_id" {
  description = "The ID of the Aurora cluster"
  value       = module.aurora.cluster_id
}

output "cluster_arn" {
  description = "The ARN of the Aurora cluster"
  value       = module.aurora.cluster_arn
}

output "security_group_id" {
  description = "The ID of the Aurora security group"
  value       = aws_security_group.aurora.id
}

output "master_user_secret_arn" {
  description = "The ARN of the master user secret"
  value       = module.aurora.cluster_master_user_secret[0].secret_arn
}

output "database_name" {
  description = "The name of the default database"
  value       = var.database_name
}
