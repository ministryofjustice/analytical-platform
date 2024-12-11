resource "aws_mwaa_environment" "main" {
  name                            = local.mwaa_environment_name
  airflow_version                 = "2.10.1"
  environment_class               = "mw1.medium"
  weekly_maintenance_window_start = "SAT:00:00"

  execution_role_arn = module.airflow_execution_iam_role.iam_role_arn

  kms_key = module.airflow_kms.key_arn

  source_bucket_arn              = module.airflow_bucket.s3_bucket_arn
  dag_s3_path                    = "dags/"
  requirements_s3_path           = "requirements.txt"
  requirements_s3_object_version = module.airflow_requirements_object.s3_object_version_id

  max_workers = 2
  min_workers = 1
  schedulers  = 2

  webserver_access_mode = "PRIVATE_ONLY"

  airflow_configuration_options = {
    "webserver.warn_deployment_exposure" = 0
    "webserver.base_url"                 = local.mwaa_webserver_base_url
    "webserver.instance_name"            = "Zephyr PoC"
  }

  network_configuration {
    security_group_ids = [module.mwaa_security_group.security_group_id]
    subnet_ids         = slice(module.vpc.private_subnets, 0, 2)
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }

    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }

    task_logs {
      enabled   = true
      log_level = "INFO"
    }

    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }

    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }
}
