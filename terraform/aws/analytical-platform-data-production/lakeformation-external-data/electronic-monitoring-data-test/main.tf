resource "aws_lakeformation_resource" "data_location" {
  provider = aws.source
  for_each = {
    for idx, loc in local.data_locations : loc.data_location => loc
    if loc.register == true
  }

  arn                     = each.value.data_location
  use_service_linked_role = true
  hybrid_access_enabled   = try(each.value.hybrid_mode, false)
}

resource "aws_lakeformation_permissions" "data_location_share" {
  provider = aws.source
  for_each = {
    for idx, loc in local.data_locations : loc.data_location => loc
  }

  principal                     = data.aws_caller_identity.destination.account_id
  permissions                   = ["DATA_LOCATION_ACCESS"]
  permissions_with_grant_option = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = each.value.data_location
  }
  depends_on = [aws_lakeformation_resource.data_location]
}

resource "aws_lakeformation_permissions" "database_share" {
  provider = aws.source
  for_each = {
    for db in local.databases : db.name => db
  }

  principal                     = data.aws_caller_identity.destination.account_id
  permissions                   = each.value.permissions
  permissions_with_grant_option = each.value.permissions

  database {
    name = each.value.name
  }

  depends_on = [aws_lakeformation_permissions.data_location_share]
}

resource "aws_lakeformation_permissions" "share_filtered_data_with_role" {
  provider = aws.source
  for_each = {
    for tbl in local.tables : tbl.source_table => tbl
  }
  principal   = data.aws_caller_identity.destination.account_id
  permissions = ["SELECT"]
  data_cells_filter {
    database_name    = each.value.source_database
    table_name       = each.key
    table_catalog_id = data.aws_caller_identity.source.account_id
    name             = each.value.data_filter_name
  }


  depends_on = [aws_lakeformation_permissions.database_share]
}

resource "aws_glue_catalog_database" "destination_database" {
  provider = aws.destination
  for_each = {
    for tbl in local.tables : tbl.source_table => tbl
  }

  name = each.value.destination_database.database_name
}

resource "aws_glue_catalog_database" "destination_account_database_resource_link" {
  provider = aws.destination
  for_each = {
    for db in local.databases : db.name => db
  }

  name = "${each.key}_resource_link"

  target_database {
    catalog_id    = data.aws_caller_identity.source.account_id
    database_name = each.key
    region        = data.aws_region.source.name
  }

  depends_on = [aws_lakeformation_permissions.share_filtered_data_with_role]
  lifecycle {
    ignore_changes = [
      # Change to description  require alter permissions which aren't typicically granted or needed
      description
    ]
  }
}

resource "aws_glue_catalog_table" "destination_account_table_resource_link" {
  provider = aws.destination
  for_each = {
    for tbl in local.tables : tbl.source_table => tbl
  }

  name          = try(each.value.resource_link_name, "${each.key}_resource_link") # what to name the resoruce link in the destintion account
  owner         = data.aws_caller_identity.source.account_id
  database_name = each.value.destination_database.database_name # what database to place the resource link into
  target_table {
    name          = each.key # the shared database
    catalog_id    = data.aws_caller_identity.source.account_id
    database_name = each.value.source_database # shared database
    region        = data.aws_region.source.name
  }
  table_type = "EXTERNAL_TABLE"

  lifecycle {
    ignore_changes = [
      # Change to description  require alter permissions which aren't typicically granted or needed
      description,
      storage_descriptor
    ]
  }

  depends_on = [aws_lakeformation_permissions.share_filtered_data_with_role]
}

