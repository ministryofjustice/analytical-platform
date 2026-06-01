output "lf_tags" {
  description = "Merged LF-Tags from all YAML files"
  value       = local.lf_tags
}

output "tag_managers" {
  description = "List of all tag managers from the configurations"
  value       = local.tag_managers
}

output "projects" {
  description = "List of projects with their configurations"
  value       = local.projects
}
