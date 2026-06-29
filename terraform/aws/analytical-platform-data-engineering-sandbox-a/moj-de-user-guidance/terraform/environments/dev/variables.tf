# terraform/environments/dev/variables.tf

# ==================== General ====================

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

# ==================== Bedrock KB ====================

variable "s3_bucket_name" {
  type = string
}

variable "skip_kb_creation" {
  type    = bool
  default = false
}

variable "skip_index_creation" {
  type    = bool
  default = false
}

variable "create_s3_bucket" {
  type        = bool
  default     = true
  description = "Set to false if S3 bucket already exists"
}

# ==================== Lambda ====================

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

variable "bedrock_model_id" {
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
  description = "Bedrock model ID"
}

variable "max_context_tokens" {
  type        = number
  default     = 4096
  description = "Max context tokens for model"
}

variable "auth_token" {
  type        = string
  description = "Bearer token for API authentication"
  sensitive   = true
}

# ==================== API Gateway ====================

variable "api_stage_name" {
  type        = string
  default     = "dev"
  description = "API Gateway stage name"
}

# ==================== Database (DynamoDB) ====================

variable "dynamodb_table_name" {
  type        = string
  default     = "RAG-ConversationLogs"
  description = "DynamoDB table name for conversation logs"
}

variable "dynamodb_pitr_enabled" {
  type        = bool
  default     = true
  description = "Enable Point-in-Time Recovery for DynamoDB"
}

variable "dynamodb_stream_enabled" {
  type        = bool
  default     = true
  description = "Enable DynamoDB Streams"
}

# ==================== Security (Guardrails) ====================

variable "guardrail_filter_strength" {
  type        = string
  default     = "MEDIUM"
  description = "Content filter strength (NONE, LOW, MEDIUM, HIGH)"
}

# ==================== GitHub OIDC ====================

variable "github_org" {
  type        = string
  description = "GitHub organization or username"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

# ==================== Bedrock Knowledge Base ID ====================

variable "kb_id" {
  type        = string
  default     = ""
  description = "Bedrock Knowledge Base ID - manually created due to SCP restrictions"
}

# ==================== Lambda Artifacts ====================

variable "artifacts_bucket" {
  type        = string
  description = "Bootstrap-owned, nuke-protected bucket holding pre-built Lambda zips"
}
