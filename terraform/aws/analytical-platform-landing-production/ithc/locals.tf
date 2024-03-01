locals {
  ithc_testers = jsondecode(data.aws_secretsmanager_secret_version.ithc_testers.secret_string)
}
