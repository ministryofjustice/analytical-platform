locals {
  sandbox_account_id = var.account_ids["analytical-platform-data-engineering-sandbox-a"]

  databases = toset([
    for table in values(var.restricted_tables) : table.database_name
  ])
}