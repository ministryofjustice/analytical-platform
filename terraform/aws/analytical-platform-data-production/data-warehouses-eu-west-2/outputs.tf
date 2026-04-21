output "home_office_copy_role_arn" {
  description = "ARN for the Home Office assume role used to read source bucket data"
  value       = var.home_office_copy_role_enabled ? module.home_office_source_s3_read_role[0].arn : null
}
