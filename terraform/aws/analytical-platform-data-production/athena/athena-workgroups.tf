resource "aws_athena_workgroup" "airflow_prod" {
  name = "airflow-prod-workgroup"

  configuration {
    bytes_scanned_cutoff_per_query  = 1000000000
    enforce_workgroup_configuration = false
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
  }

  tags = merge(var.tags,
    {
      "Name"             = "airflow-prod-workgroup"
      "application"      = "Airflow"
      "environment-name" = "prod"
      "is-production"    = "True"
      "owner"            = "Data Engineering:dataengineering@digital.justice.gov.uk"
    }
  )
}
