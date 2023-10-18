resource "aws_sagemaker_domain" "studio_domain" {
  domain_name = "mvp-studio-domain"
  auth_mode   = "IAM" # Using IAM for authentication

  app_network_access_type = "PublicInternetOnly"

  default_user_settings {
    execution_role = aws_iam_role.sagemaker_studio_execution_role.arn
  }

  vpc_id     = "YOUR_VPC_ID"      # Replace with your VPC ID
  subnet_ids = ["YOUR_SUBNET_ID"] # Replace with your Subnet ID(s)
}
