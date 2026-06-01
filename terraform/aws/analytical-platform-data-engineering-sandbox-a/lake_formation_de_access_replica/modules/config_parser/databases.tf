locals {
  # Extract databases from all YAML files
  databases_list = [
    for c in values(local.yaml_contents) :
    try(c.databases, [])
  ]

  # Flatten all databases into a single map
  databases = {
    for db in flatten(local.databases_list) :
    db.name => {
      name                            = db.name
      location_bucket_name            = db.location_bucket_name
      location_prefix                 = try(db.location_prefix, null)
      shared_with_analytical_platform = try(db.shared_with_analytical_platform, false)
      kms_key_id                      = try(db.kms_key_id, null)
      admins                          = try(db.admins, [])
    }
  }

  tables_by_database = {}
}

output "databases" {
  description = "List of top-level directories in the database definitions path"
  value       = local.databases
}

output "tables_by_database" {
  description = "Tables grouped by database"
  value       = local.tables_by_database
}
