#trivy:ignore:avd-aws-0066:X-Ray is not required for this service
module "cloudtrail_athena_event_processor_function" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/lambda/aws"
  version = "8.1.2"

  function_name = "cloudtrail-athena-event-processor"
  description   = "Processes incoming CloudTrail events and forwards them to CloudWatch Logs"
  handler       = "main.lambda_handler"
  runtime       = "python3.12"
  timeout       = 120

  source_path                  = "${path.module}/src/cloudtrail-athena-event-processor"
  trigger_on_package_timestamp = false

  allowed_triggers = {
    "logs" = {
      principal = "logs.amazonaws.com"
    }
  }
  create_current_version_allowed_triggers = false

  environment_variables = {
    CLOUDWATCH_LOG_GROUP_NAME = module.cloudtrail_athena_events_log_group.cloudwatch_log_group_name
  }

  attach_policy_statements = true
  policy_statements = {
    logs_access = {
      sid    = "AllowCloudWatchLogs"
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = ["${module.cloudtrail_athena_events_log_group.cloudwatch_log_group_arn}:*"]
    }
  }
}
