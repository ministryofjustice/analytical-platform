output "issuer_identifier" {
  value       = aws_iam_outbound_web_identity_federation.this.issuer_identifier
  description = "Account-specific issuer URL for OIDC trust policies (e.g. Octo STS)"
}
