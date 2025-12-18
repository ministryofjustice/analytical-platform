resource "aws_athena_workgroup" "create_a_derived_table_dev" {
  name = "dbt-probation-dev"

  configuration {
    bytes_scanned_cutoff_per_query  = 1099511627776000
    enforce_workgroup_configuration = false
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = "s3://${module.query_results_dev.bucket.id}/"
    }
  }

  tags = merge(var.tags, 
    {
      "environment" = "dev"
      "is_production" = "false"
    }
  )
}
