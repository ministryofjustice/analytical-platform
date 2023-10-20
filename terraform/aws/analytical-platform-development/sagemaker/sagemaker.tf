resource "aws_sagemaker_domain" "studio_domain" {
  domain_name = var.domain_name
  auth_mode   = var.auth_mode

  # default_space_settings {
  #   execution_role = aws_iam_role.sagemaker_studio_execution_role.arn
  # }

  default_user_settings {
    execution_role  = aws_iam_role.sagemaker_studio_execution_role.arn
    security_groups = [module.vpc.default_security_group_id]
    jupyter_server_app_settings {
      lifecycle_config_arns = []

      default_resource_spec {
        instance_type       = "system"
        sagemaker_image_arn = "arn:aws:sagemaker:eu-west-2:712779665605:image/jupyter-server-3"
      }
    }

    sharing_settings {
      notebook_output_option = "Allowed"
      s3_output_path         = "s3://sagemaker-studio-on6mcpqk2ec/sharing"
    }
  }

  # # app_network_access_type = "PublicInternetOnly"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # single_sign_on_managed_application_instance_id = "YOUR_SSO_APP_INSTANCE_ID"
}
