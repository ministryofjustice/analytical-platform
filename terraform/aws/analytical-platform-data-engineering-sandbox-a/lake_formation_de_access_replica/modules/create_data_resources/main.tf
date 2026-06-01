# Create resource link in destination account
resource "aws_glue_catalog_database" "database_resource_links" {
  provider = aws.destination
  for_each = toset(local.database_info)
  name     = "${var.database_prefix}_${each.key}"

  target_database {
    catalog_id    = data.aws_caller_identity.source.account_id
    database_name = each.key
    region        = data.aws_region.source.region
  }

  lifecycle {
    ignore_changes = [
      description,
      parameters,
      tags,
      location_uri,
    ]
  }
}

# Create data cell filter in source account
resource "aws_lakeformation_data_cells_filter" "data_cell_filter" {
  provider = aws.source
  for_each = tomap(local.table_info_with_row_filter)

  table_data {
    database_name    = each.value.database_name
    name             = "${each.value.database_name}-${each.value.table_name}-filter"
    table_catalog_id = data.aws_caller_identity.source.account_id
    table_name       = each.value.table_name
    column_wildcard {
      excluded_column_names = []
    }
    row_filter {
      filter_expression = each.value.row_filter
    }
  }
}
