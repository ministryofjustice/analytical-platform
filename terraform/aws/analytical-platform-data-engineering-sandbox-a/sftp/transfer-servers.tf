
resource "aws_transfer_server" "this" {
  protocols                        = ["SFTP"]
  identity_provider_type           = "SERVICE_MANAGED"
  domain                           = "S3"
  post_authentication_login_banner = "Welcome to the Analytical Platform Family SFTP Server."

  endpoint_type = "PUBLIC"

  security_policy_name = "TransferSecurityPolicy-2024-01"

  logging_role = module.transfer_family_service_role.iam_role_arn

  structured_log_destinations = [
    "${aws_cloudwatch_log_group.transfer_structured_logs.arn}:*"
  ]
}

