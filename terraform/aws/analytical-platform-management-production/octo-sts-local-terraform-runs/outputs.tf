output "octo_sts_local_terraform_role_arn" {
  value       = module.octo_sts_local_terraform_iam_role.arn
  description = "Role ARN to use as the Octo STS trust policy subject"
}
