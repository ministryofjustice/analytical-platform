output "guardrail_id" {
  description = "The ID of the Bedrock guardrail"
  value       = aws_bedrock_guardrail.this.guardrail_id
}

output "guardrail_arn" {
  description = "The ARN of the Bedrock guardrail"
  value       = aws_bedrock_guardrail.this.guardrail_arn
}

output "guardrail_version" {
  description = "The published version of the guardrail"
  value       = aws_bedrock_guardrail_version.this.version
}