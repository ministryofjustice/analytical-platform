locals {
  tags = merge(var.tags, {
    project = var.project_name
  })

  project_name = var.project_name
  environment  = var.environment
}
