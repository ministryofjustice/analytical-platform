#tfsec:ignore:avd-aws-0066:no need for tracing
module "jml_extract_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  publish        = true
  create_package = false

  function_name = "data_platform_jml_extract"
  description   = "Generates a JML report and sends it to JMLv4"
  package_type  = "Image"
  memory_size   = 512
  timeout       = 120
  image_uri     = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-jml-extract-lambda-ecr-repo:1.0.3"

  environment_variables = {
    SECRET_ID       = data.aws_secretsmanager_secret_version.govuk_notify_api_key.id
    LOG_GROUP_NAMES = module.auth0_log_streams["alpha-analytics-moj"].cloudwatch_log_group_name
    EMAIL_SECRET    = data.aws_secretsmanager_secret_version.jml_email.id
    TEMPLATE_ID     = "de618989-db86-4d9a-aa55-4724d5485fa5"
  }

  attach_policy_statements = true
  policy_statements = {
    "cloudwatch" = {
      sid    = "CloudWatch"
      effect = "Allow"
      actions = [
        "cloudwatch:GenerateQuery",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:GetLogEvents",
        "logs:StartQuery",
        "logs:StopQuery",
        "logs:GetQueryExecution",
        "logs:GetQueryResults"
      ]
      resources = [
        "${module.auth0_log_streams["alpha-analytics-moj"].cloudwatch_log_group_arn}:*"
      ]
    }
    "secretsmanager" = {
      sid    = "SecretsManager"
      effect = "Allow"
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:ListSecrets"
      ]
      resources = [
        aws_secretsmanager_secret.govuk_notify_api_key.arn,
        aws_secretsmanager_secret.jml_email.arn
      ]
    }
  }

  allowed_triggers = {
    "eventbridge" = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.jml_lambda_trigger.arn
    }
  }
}

module "auth0_log_streams" {
  source = "../auth0-log-streams"

  tags        = var.tags
  account_ids = var.account_ids
}
