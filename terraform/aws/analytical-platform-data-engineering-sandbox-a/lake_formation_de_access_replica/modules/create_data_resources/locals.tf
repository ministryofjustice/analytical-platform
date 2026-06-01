locals {
  databases_path  = abspath("${path.root}/../data_hub_accounts/${var.data_hub_account_path}")
  databases_files = fileset(local.databases_path, "**/config.yaml")
  databases_contents = {
    for edf in local.databases_files :
    edf => yamldecode(file("${local.databases_path}/${edf}"))
  }
  database_info = [
    for file_path, file_contents in local.databases_contents : file_contents.database_name
  ]
  table_info = merge([
    for file_path, file_contents in local.databases_contents : {
      for table_name, table_config in file_contents.tables :
      "${file_contents.database_name}-${table_name}" => {
        database_name = file_contents.database_name
        table_name    = table_name
        row_filter    = table_config != null ? coalesce(table_config.row_filter, "") : ""
      }
    }
  ]...)

  table_info_with_row_filter = {
    for key, val in local.table_info :
    key => val
    if val.row_filter != ""
  }

  table_info_all_rows = {
    for key, val in local.table_info :
    key => val
    if val.row_filter == ""
  }

}
