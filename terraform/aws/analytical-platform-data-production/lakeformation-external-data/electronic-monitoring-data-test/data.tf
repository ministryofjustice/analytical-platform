##################################################
# AWS
##################################################

data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_caller_identity" "destination" {
  provider = aws.destination
}

data "aws_caller_identity" "source" {
  provider = aws.source
}

data "aws_region" "source" {
  provider = aws.source
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}


### Account Information

data "aws_secretsmanager_secret" "account_ids" {
  provider = aws.session
  name     = "analytical-platform/platform-account-ids"
}

data "aws_secretsmanager_secret_version" "account_ids_version" {
  provider  = aws.session
  secret_id = data.aws_secretsmanager_secret.account_ids.id
}


## Data eng role
data "aws_iam_roles" "data_engineering_team_access_role_data_engineering_production_data_eng" {
  provider = aws.destination

  name_regex  = "AWSReservedSSO_modernisation-platform-data-eng_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
