output "database_name" {
  description = "The name of the lakeformation database"
  value       = aws_glue_catalog_database.lakeformation_database.name
}

output "location_uri" {
  description = "The S3 location URI of the lakeformation database"
  value       = aws_glue_catalog_database.lakeformation_database.location_uri
}

output "location_arn" {
  description = "The ARN of the lakeformation location resource"
  value       = aws_lakeformation_resource.lakeformation_location.arn
}
