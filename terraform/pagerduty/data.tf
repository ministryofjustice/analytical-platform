data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret" "pagerduty_token" {
  name = "pagerduty-token"
}

data "aws_secretsmanager_secret_version" "pagerduty_token" {
  secret_id = data.aws_secretsmanager_secret.pagerduty_token.id
}

# adding as they are managed elsewhere
# https://github.com/ministryofjustice/ecp-infrastructure/blob/main/terraform/pagerduty/pagerduty-users-teams.tf#L18
data "pagerduty_user" "lauren_taylor_brown" {
  email = "lauren.taylor-brown@justice.gov.uk"
}

