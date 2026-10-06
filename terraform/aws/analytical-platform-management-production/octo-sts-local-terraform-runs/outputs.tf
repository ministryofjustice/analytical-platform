output "outbound_web_identity_federation_issuer" {
  value       = aws_iam_outbound_web_identity_federation.this.issuer_identifier
  description = "Account-specific issuer URL to use as the Octo STS trust policy issuer"
}

output "octo_sts_local_terraform_role_arn" {
  value       = module.octo_sts_local_terraform_iam_role.arn
  description = "Role ARN to use as the Octo STS trust policy subject"
}
