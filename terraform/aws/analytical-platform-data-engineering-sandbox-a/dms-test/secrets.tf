resource "aws_secretsmanager_secret" "slack_webhook" {
  name = "${local.name}-slack-webhook"
}