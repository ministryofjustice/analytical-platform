
resource "aws_transfer_server" "this" {
  protocols              = ["SFTP"]
  identity_provider_type = "SERVICE_MANAGED"
  domain                 = "S3"

  endpoint_type = "VPC"
  endpoint_details {
    vpc_id     = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets
  }

  # workflow_details {
  #   execution_role = module.transfer_family_service_role.iam_role_arn
  #   workflow_details {
  #     name = "TransferWorkflow-2024-01"
  #   }
  #   on_partial_upload {

  #   }
  #   on_upload {

  #   }
  # }

  security_policy_name = "TransferSecurityPolicy-2024-01"

  logging_role = module.transfer_family_service_role.iam_role_arn
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.transfer.arn}:*"
  ]
}

resource "aws_cloudwatch_log_group" "transfer" {
  name_prefix = "transfer_"
}
