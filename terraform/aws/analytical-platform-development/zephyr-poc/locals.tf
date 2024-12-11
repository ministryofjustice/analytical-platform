locals {
  project_name            = "mojap-zephyr-poc"
  bucket_name             = "${local.project_name}-airflow"
  execution_policy_name   = "${local.project_name}-airflow-execution"
  execution_role_name     = "${local.project_name}-airflow-execution"
  security_group_name     = "${local.project_name}-mwaa"
  mwaa_environment_name   = local.project_name
  mwaa_webserver_base_url = "zephyr.dev.analytical-platform.service.justice.gov.uk"
}
