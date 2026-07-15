output "namespace_id" {
  description = "The ID of the Redshift Serverless namespace"
  value       = aws_redshiftserverless_namespace.this.id
}

output "workgroup_id" {
  description = "The ID of the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.this.id
}

output "endpoint_address" {
  description = "The DNS address for this Redshift Serverless instance"
  value       = aws_redshiftserverless_workgroup.this.endpoint[0].address
}

output "endpoint_port" {
  description = "The port that this Redshift Serverless instance listens on"
  value       = aws_redshiftserverless_workgroup.this.endpoint[0].port
}

output "security_group_id" {
  description = "The ID of the Security Group that controls access to Redshift"
  value       = module.redshift_sg.security_group_id
}

output "iam_role_arn" {
  description = "The ARN of the IAM role attached to Redshift"
  value       = aws_iam_role.redshift.arn
}

output "admin_secret_arn" {
  description = "The ARN of the admin user secret in Secrets Manager"
  value       = aws_redshiftserverless_namespace.this.admin_password_secret_arn
}
