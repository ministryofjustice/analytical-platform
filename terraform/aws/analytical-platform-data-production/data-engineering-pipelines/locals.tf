locals {

  protected_dbs = [
    {
      name                    = "xhibit"
      database_string_pattern = ["xhibit_*"]
      role_names_to_exempt = [
        "courts-data-engineer",
        "airflow_prod_xhibit_etl",
        "airflow_dev_xhibit_etl_athena",
        "restricted-admin",
      ]
    },
    {
      name = "mags"
      database_string_pattern = [
        "mags_curated_*",
        "mags_processed_*",
      ]
      role_names_to_exempt = [
        "courts-data-engineer",
        "airflow_prod_mags_data_processor",
        "restricted-admin",
        "airflow_dev_mags_data_processor",
      ]
    },
    {
      name                    = "familyman"
      database_string_pattern = ["familyman_*"]
      role_names_to_exempt = [
        "data-first-data-engineer",
        "airflow_family_ap",
        "restricted-admin",
        "alpha_user_lavmatt",
        "airflow_prod_familyman",
        "airflow_dev_familyman",
      ]
    },
    {
      name                    = "delius"
      database_string_pattern = ["delius*"]
      role_names_to_exempt = [
        "prison-probation-data-engineer",
        "data-engineering-infrastructure",
        "create-a-derived-table",
        "github-actions-infrastructure",
        "restricted-admin",
      ]
    },
    {
      name                    = "oasys"
      database_string_pattern = ["oasys*"]
      role_names_to_exempt = [
        "prison-probation-data-engineer",
        "data-engineering-infrastructure",
        "create-a-derived-table",
        "github-actions-infrastructure",
        "restricted-admin",
      ]
    },
    {
      name                    = "nomis"
      database_string_pattern = ["nomis*"]
      role_names_to_exempt = [
        "prison-probation-data-engineer",
        "airflow_prod_nomis_transform",
        "airflow_prod_nomis_ao",
        "airflow_prod_nomis_ao_legacy",
        "airflow_prod_nomis_derive",
        "airflow_dev_nomis_transform",
        "airflow_dev_nomis_ao",
        "airflow_dev_nomis_ao_legacy",
        "airflow_dev_nomis_derive",
        "restricted-admin",
        "create-a-derived-table"
      ]
    },
    {
      name                    = "pathfinder"
      database_string_pattern = ["pathfinder*"]
      role_names_to_exempt = [
        "prison-probation-data-engineer",
        "restricted-admin",
      ]
    },
    {
      name = "caseman"
      database_string_pattern = [
        "caseman_v*",
        "caseman_dev_v*",
        "caseman_derived_v*",
        "caseman_derived_dev_v*",
      ]
      role_names_to_exempt = [
        "restricted-admin",
        "cc-data-engineer",
        "data-first-data-engineer",
        "airflow_prod_civil",
        "airflow_dev_civil",
      ]
    },
    {
      name = "pcol"
      database_string_pattern = [
        "pcol_v*",
        "pcol_dev_v*",
        "pcol_derived_v*",
        "pcol_derived_dev_v*",
      ]
      role_names_to_exempt = [
        "restricted-admin",
        "cc-data-engineer",
        "data-first-data-engineer",
        "airflow_prod_civil",
        "airflow_dev_civil",
      ]
    }
  ]

  unique_role_names = distinct(flatten([for db in local.protected_dbs : db.role_names_to_exempt])) // to retrieve unique_ids
}
