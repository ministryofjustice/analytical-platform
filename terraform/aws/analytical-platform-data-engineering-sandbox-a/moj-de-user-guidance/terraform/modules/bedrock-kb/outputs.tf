output "knowledge_base_id" {
  value = var.skip_kb_creation ? null : awscc_bedrock_knowledge_base.kb[0].id
}

output "knowledge_base_arn" {
  value = var.skip_kb_creation ? null : awscc_bedrock_knowledge_base.kb[0].knowledge_base_arn
}

output "collection_endpoint" {
  value = aws_opensearchserverless_collection.vector.collection_endpoint
}

output "collection_arn" {
  value = aws_opensearchserverless_collection.vector.arn
}

output "kb_role_arn" {
  value = aws_iam_role.bedrock_kb_role.arn
}

output "debug_caller_arn" {
  value = local.caller_arn
}

output "debug_assumed_role_name" {
  value = local.assumed_role_name
}

output "debug_caller_role_arn" {
  value = local.caller_role_arn
}
