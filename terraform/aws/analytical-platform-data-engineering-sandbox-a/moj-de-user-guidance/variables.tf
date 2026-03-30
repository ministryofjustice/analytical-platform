variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "kb_id" {
  type        = string
  description = "Bedrock Knowledge Base ID"
  default     = ""
}

variable "model_id" {
  type        = string
  description = "Bedrock Model ID"
  default     = "anthropic.claude-3-5-sonnet-20241022-v2:0"
}

variable "max_context_tokens" {
  type        = number
  description = "Maximum context tokens for RAG"
  default     = 4000
}
