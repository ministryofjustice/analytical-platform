resource "aws_lakeformation_permissions" "database_describe" {
  provider = aws.session

  for_each = local.databases

  principal   = var.restricted_principal_arn
  permissions = ["DESCRIBE"]

  database {
    catalog_id = local.sandbox_account_id
    name       = each.value
  }
}

resource "aws_lakeformation_data_cells_filter" "restricted" {
  provider = aws.session

  for_each = var.restricted_tables

  table_data {
    table_catalog_id = local.sandbox_account_id
    database_name    = each.value.database_name
    table_name       = each.value.table_name
    name             = "${each.key}-restricted-filter"

    column_names = each.value.allowed_columns

    row_filter {
      filter_expression = each.value.row_filter
    }
  }
}

resource "aws_lakeformation_permissions" "restricted_filter_select" {
  provider = aws.session

  for_each = var.restricted_tables

  principal   = var.restricted_principal_arn
  permissions = ["SELECT"]

  data_cells_filter {
    table_catalog_id    = local.sandbox_account_id
    database_name = each.value.database_name
    table_name    = each.value.table_name
    name          = aws_lakeformation_data_cells_filter.restricted[each.key].table_data[0].name
  }

  depends_on = [
    aws_lakeformation_permissions.database_describe,
    aws_lakeformation_data_cells_filter.restricted
  ]
}