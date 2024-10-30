##################################################
# AWS
##################################################

data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_caller_identity" "source" {
  provider = aws.digital_prisons_reporting_preprod_eu_west_2
}

data "aws_caller_identity" "destination" {

}

data "aws_region" "source" {
  provider = aws.digital_prisons_reporting_preprod_eu_west_2
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
