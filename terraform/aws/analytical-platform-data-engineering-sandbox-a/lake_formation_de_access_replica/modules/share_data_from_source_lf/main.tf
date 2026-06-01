
# Data Location
resource "aws_lakeformation_permissions" "share_data_bucket_alpha_users" {
  for_each = { for s in local.users : "${s.role_name}" => s }
  provider = aws.source

  principal   = "arn:aws:iam::${data.aws_caller_identity.destination.account_id}:role/${each.value.role_name}"
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = "arn:aws:s3:::${var.bucket_name}"
  }
}

# Describe database
resource "aws_lakeformation_permissions" "database_grants" {
  for_each = { for s in local.user_db_info : "${s.role_name}-${s.database_name}" => s }
  provider = aws.source

  permissions = ["DESCRIBE"]
  principal   = "arn:aws:iam::${data.aws_caller_identity.destination.account_id}:role/${each.value.role_name}"

  database {
    name = each.value.database_name
  }
}

# Describe table
resource "aws_lakeformation_permissions" "table_grants_describe_only" {
  for_each = { for s in local.user_grants : "${s.role_name}-${s.database_name}-${s.table_name}" => s }
  provider = aws.source

  permissions = ["DESCRIBE"]
  principal   = "arn:aws:iam::${data.aws_caller_identity.destination.account_id}:role/${each.value.role_name}"

  table {
    name          = each.value.table_name
    database_name = each.value.database_name
  }
}
