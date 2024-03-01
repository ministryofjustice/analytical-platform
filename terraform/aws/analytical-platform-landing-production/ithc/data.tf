##################################################
# AWS
##################################################

# Calling session
data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_iam_roles" "analytical_platform_landing_production_sso_administrator_access_roles" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_availability_zones" "available" {}

data "aws_secretsmanager_secret" "ithc_testers" {
  arn = module.secrets_manager.secret_arn
}

data "aws_secretsmanager_secret_version" "ithc_testers" {
  secret_id = data.aws_secretsmanager_secret.ithc_testers.id
}
