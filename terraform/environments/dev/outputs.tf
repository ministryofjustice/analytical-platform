output "knowledge_base_id" {
  value = module.bedrock_kb.knowledge_base_id
}

output "knowledge_base_arn" {
  value = module.bedrock_kb.knowledge_base_arn
}

output "collection_endpoint" {
  value = module.bedrock_kb.collection_endpoint
}

output "debug_caller_arn" {
  value = module.bedrock_kb.debug_caller_arn
}

output "debug_assumed_role_name" {
  value = module.bedrock_kb.debug_assumed_role_name
}

output "debug_caller_role_arn" {
  value = module.bedrock_kb.debug_caller_role_arn
}