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

variable "lambda_layer_name" {
  type        = string
  default     = "smart-rag-dependencies"
  description = "Name of existing Lambda layer"
}

variable "lambda_role_name" {
  type        = string
  description = "Name of existing Lambda execution role"
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
  default     = "prod"
  description = "API Gateway stage name"
}

# ==================== GitHub OIDC ====================

variable "github_role_arn" {
  type        = string
  description = "GitHub Actions OIDC role ARN for AOSS access"
}
