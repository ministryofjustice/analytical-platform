resource "aws_transfer_user" "user" {
  server_id = aws_transfer_server.this.id
  user_name = var.user_name
  role      = module.transfer_family_service_role.iam_role_arn

  # TODO: This should be refactored, in particular the target
  home_directory_type = "LOGICAL"
  home_directory_mappings {
    entry  = "/workspace"
    target = "/${module.landing_bucket.s3_bucket_id}/$${Transfer:UserName}"
  }

  # TODO: Tagging
}
