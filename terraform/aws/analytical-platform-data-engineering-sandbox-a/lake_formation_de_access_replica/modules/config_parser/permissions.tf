locals {
  # Parse permissions from each file
  lf_tags_permissions_list = [
    for c in values(local.yaml_contents) :
    try(c.lf_tags_permissions, [])
  ]

  # Flatten permissions list
  lf_tags_permissions = flatten(local.lf_tags_permissions_list)
}

output "lf_tags_permissions" {
  value = local.lf_tags_permissions
}
