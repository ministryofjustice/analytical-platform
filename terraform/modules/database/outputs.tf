# modules/database/outputs.tf

output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.conversation_logs.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.conversation_logs.arn
}

output "table_id" {
  description = "DynamoDB table ID"
  value       = aws_dynamodb_table.conversation_logs.id
}

output "stream_arn" {
  description = "DynamoDB stream ARN (for future Lambda triggers)"
  value       = aws_dynamodb_table.conversation_logs.stream_arn
}

output "gsi_user_time_index" {
  description = "UserTimeIndex GSI name"
  value       = "UserTimeIndex"
}

output "gsi_session_index" {
  description = "SessionIndex GSI name"
  value       = "SessionIndex"
}