#trivy:ignore:avd-aws-0006:Not encrypting the workgroup currently
resource "aws_athena_workgroup" "airflow_dev" {
  #checkov:skip=CKV_AWS_159:Not encrypting the workgroup currently

  name = "airflow-dev-workgroup"

  configuration {
    bytes_scanned_cutoff_per_query  = 1099511627776
    enforce_workgroup_configuration = true
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = "s3://mojap-athena-query-dump/airflow-dev-workgroup"
    }
  }

  tags = merge(var.tags,
    {
      "Name"          = "airflow-dev-workgroup"
      "application"   = "Data Engineering Airflow"
      "environment"   = "development"
      "is-production" = "true"
      "owner"         = "data-engineering:dataengineering@digital.justice.gov.uk"
    }
  )
}

#trivy:ignore:avd-aws-0006:Not encrypting the workgroup currently
resource "aws_athena_workgroup" "airflow_prod" {
  #checkov:skip=CKV_AWS_159:Not encrypting the workgroup currently

  name = "airflow-prod-workgroup"

  configuration {
    bytes_scanned_cutoff_per_query  = 1099511627776
    enforce_workgroup_configuration = true
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = "s3://mojap-athena-query-dump/airflow-prod-workgroup"
    }
  }

  tags = merge(var.tags,
    {
      "Name"          = "airflow-prod-workgroup"
      "application"   = "airflow"
      "environment"   = "production"
      "is-production" = "true"
      "owner"         = "data-engineering:dataengineering@digital.justice.gov.uk"
    }
  )
}

#trivy:ignore:avd-aws-0006:Not encrypting the workgroup currently
resource "aws_athena_workgroup" "airflow_dev_hmcts" {
  #checkov:skip=CKV_AWS_159:Not encrypting the workgroup currently

  name = "airflow-dev-workgroup-hmcts"

  configuration {
    bytes_scanned_cutoff_per_query  = 1099511627776
    enforce_workgroup_configuration = true
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = "s3://mojap-athena-query-dump/airflow-dev-workgroup-hmcts"
    }
  }

  tags = merge(var.tags,
    {
      "Name"          = "airflow-dev-workgroup-hmcts"
      "application"   = "Data Engineering Airflow"
      "environment"   = "development"
      "is-production" = "true"
      "owner"         = "data-engineering:dataengineering@digital.justice.gov.uk"
      "business-unit" = "HMCTS"
    }
  )
}

#trivy:ignore:avd-aws-0006:Not encrypting the workgroup currently
resource "aws_athena_workgroup" "airflow_prod_hmcts" {
  #checkov:skip=CKV_AWS_159:Not encrypting the workgroup currently

  name = "airflow-prod-workgroup-hmcts"

  configuration {
    bytes_scanned_cutoff_per_query  = 1099511627776
    enforce_workgroup_configuration = true
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = "s3://mojap-athena-query-dump/airflow-prod-workgroup-hmcts"
    }
  }

  tags = merge(var.tags,
    {
      "Name"          = "airflow-prod-workgroup"
      "application"   = "Data Engineering Airflow"
      "environment"   = "production"
      "is-production" = "true"
      "owner"         = "data-engineering:dataengineering@digital.justice.gov.uk"
      "business-unit" = "HMCTS"
    }
  )
}
