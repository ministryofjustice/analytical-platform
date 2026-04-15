# all inputs such as (kb_id, auth_token,..)

# modules/lambda/variables.tf

variable "region" {
  type        = string
  description = "AWS region"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
}

# ==================== Lambda Config ====================

variable "lambda_timeout" {
  type        = number
  default     = 30
  description = "Lambda timeout in seconds"
}

variable "lambda_memory" {
  type        = number
  default     = 512
  description = "Lambda memory in MB"
}

variable "lambda_runtime" {
  type        = string
  default     = "python3.12"
  description = "Lambda runtime"
}

# ==================== Layer ====================

variable "lambda_layer_name" {
  type        = string
  default     = "smart-rag-dependencies"
  description = "Name of existing Lambda layer"
}

# ==================== IAM ====================

variable "lambda_role_name" {
  type        = string
  description = "Name of existing Lambda execution role"
}

# ==================== Environment Variables ====================

variable "kb_id" {
  type        = string
  description = "Bedrock Knowledge Base ID"
  sensitive   = true
}

variable "model_id" {
  type        = string
  description = "Bedrock Model ID"
}

variable "max_context_tokens" {
  type        = number
  default     = 4096
  description = "Max context tokens for model"
}

variable "auth_token" {
  type        = string
  description = "Bearer token for authorizer"
  sensitive   = true
}

# ==================== AOSS ====================

variable "aoss_collection_endpoint" {
  type        = string
  description = "AOSS collection endpoint (passed from bedrock-kb module)"
}

# ==================== Tags ====================

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}

# ==================== Guardrails ====================
variable "guardrail_id" {
  type        = string
  description = "Bedrock Guardrail ID"
  default     = ""
}

variable "guardrail_version" {
  type        = string
  description = "Bedrock Guardrail Version"
  default     = ""
}

# ==================== DynamoDB ====================

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for conversation logs"
  default     = "RAG-ConversationLogs"
}