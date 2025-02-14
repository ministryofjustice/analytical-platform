locals {
  airflow_athena_workgroups = {
    "airflow-dev" = {
      name = "airflow-dev-workgroup"
    }
    "airflow-prod" = {
      name = "airflow-prod-workgroup"
    }   
    "airflow-dev-hmcts" = {
      name          = "airflow-dev-workgroup-hmcts"
      business_unit = "HMCTS"
      component     = "airflow-hmcts-dev"
    }
    "airflow-prod-hmcts" = {
      name          = "airflow-prod-workgroup-hmcts"
      business_unit = "HMCTS"
      component     = "airflow-hmcts-prod"
    }
    "airflow-prod-corp" = {
      name          = "airflow-prod-workgroup-corp"
      business_unit = "CORP"
      component     = "airflow-corp-prod"
    }
  }
  dbt_athena_workgroups = {
    "dbt-avature" = {
      name = "dbt-avature"
    },
    "dbt-athena-spark" = {
      name = "dbt-athena-spark"
    }
  }
}

#trivy:ignore:avd-aws-0006:Not encrypting the workgroup currently
resource "aws_athena_workgroup" "airflow" {
  #checkov:skip=CKV_AWS_159:Not encrypting the workgroup currently

  for_each = local.airflow_athena_workgroups

  name = each.value.name

  configuration {
    bytes_scanned_cutoff_per_query  = 1099511627776
    enforce_workgroup_configuration = true
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = "s3://mojap-athena-query-dump"
    }
  }

  tags = merge(var.tags,
    {
      "Name"             = each.value.name
      "application"      = "airflow"
      "business-unit"    = try(each.value.business_unit, var.tags["business-unit"])
      "component"        = try(each.value.component, var.tags["component"])
      "environment-name" = strcontains(each.value.name, "prod") ? "prod" : "dev"
      "is-production"    = strcontains(each.value.name, "prod") ? "True" : "False"
      "owner"            = "Data Engineering:dataengineering@digital.justice.gov.uk"
    }
  )
}

#trivy:ignore:avd-aws-0006:Not encrypting the workgroup currently
#trivy:ignore:avd-aws-0007:Can't enforce output location due to DBT requirements
resource "aws_athena_workgroup" "dbt" {
  #checkov:skip=CKV_AWS_159:Not encrypting the workgroup currently
  #checkov:skip=CKV_AWS_82:Can't enforce output location due to DBT requirements

  for_each = local.dbt_athena_workgroups

  name = each.value.name

  configuration {
    bytes_scanned_cutoff_per_query  = 1099511627776000
    enforce_workgroup_configuration = false
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = "s3://dbt-query-dump/"
    }
  }

  tags = merge(var.tags,
    {
      "Name"             = each.value.name
      "application"      = "CaDeT"
      "business-unit"    = try(each.value.business_unit, var.tags["business-unit"])
      "component"        = try(each.value.component, var.tags["component"])
      "environment-name" = strcontains(each.value.name, "dev") ? "dev" : "prod"
      "is-production"    = strcontains(each.value.name, "dev") ? "False" : "True"
      "owner"            = "Data Engineering:dataengineering@digital.justice.gov.uk"
    }
  )
}
