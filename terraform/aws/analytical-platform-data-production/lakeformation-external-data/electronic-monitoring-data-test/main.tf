
resource "aws_glue_catalog_database" "destination_account_database_resource_link" {
  provider = aws.destination
  for_each = {
    for db in local.source_databases : db.source_name => db
  }

  name = "em_${each.key}"

  target_database {
    catalog_id    = data.aws_caller_identity.source.account_id
    database_name = each.key
    region        = data.aws_region.source.name
  }

  lifecycle {
    ignore_changes = [
      description
    ]
  }
}
