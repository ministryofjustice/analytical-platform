locals {
  databases_path  = abspath("${path.root}/../data_hub_accounts/${var.data_hub_account_path}")
  databases_files = fileset(local.databases_path, "**/config.yaml")
  databases_contents = {
    for df in local.databases_files :
    df => yamldecode(file("${local.databases_path}/${df}"))
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
  projects_path = abspath("${path.root}/../projects")
  project_files = fileset(local.projects_path, "*.yaml")
  project_contents = {
    for pf in local.project_files :
    pf => yamldecode(file("${local.projects_path}/${pf}"))
  }
  relevant_projects = {
    for file, proj in local.project_contents :
    file => proj
    if contains(keys(proj.data_hub_accounts), var.data_hub_account_path)
  }

  user_info = merge([
    for project_file, project in local.relevant_projects : {
      for user in project.users :
      user => {
        for db_name, tables in project.data_hub_accounts[var.data_hub_account_path].databases :
        db_name => coalesce(tables, [])
      }
    }
  ]...)


  user_grants = flatten([
    for user, dbs in local.user_info : [
      for db_name, tables in dbs : (
        length(tables) == 0 ? [
          {
            role_name     = user
            database_name = db_name
            table_name    = "*"
            wildcard      = true
          }
        ] : [
          for table in tables : {
            role_name     = user
            database_name = db_name
            table_name    = table
            wildcard      = false
          }
        ]
      )
    ]
  ])
  user_db_info = distinct(flatten([
    for user, dbs in local.user_info : [
      for db_name, tables in dbs : {
        role_name     = user
        database_name = db_name
      }
    ]
  ]))
  users = distinct([
    for user, _ in local.user_info :
    { role_name = user }
  ])


  user_grants_with_row_filter = [
    for grant in local.user_grants : grant
    if grant.table_name != "*" && lookup(local.table_info, "${grant.database_name}-${grant.table_name}", { row_filter = "" }).row_filter != ""
  ]

  user_grants_all_rows = [
    for grant in local.user_grants : grant
    if grant.table_name == "*" || lookup(local.table_info, "${grant.database_name}-${grant.table_name}", { row_filter = "" }).row_filter == ""
  ]
}
