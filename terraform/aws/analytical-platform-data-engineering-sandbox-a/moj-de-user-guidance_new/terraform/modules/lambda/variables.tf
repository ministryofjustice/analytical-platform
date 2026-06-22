# terraform/modules/lambda/variables.tf
# Input variables for the Lambda module

# ==================== Required Variables ====================

variable "region" {
  type        = string
  description = "AWS region for deployment"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

# ==================== Bedrock Configuration ====================

variable "kb_id" {
  type        = string
  description = "Bedrock Knowledge Base ID"
  sensitive   = true
}

variable "model_id" {
  type        = string
  description = "Bedrock Model ID (e.g., anthropic.claude-3-sonnet-20240229-v1:0)"
}

variable "max_context_tokens" {
  type        = number
  default     = 4096
  description = "Maximum context tokens for RAG responses"
}

# ==================== Guardrails Configuration ====================

variable "guardrail_id" {
  type        = string
  description = "Bedrock Guardrail ID (optional)"
  default     = ""
}

variable "guardrail_version" {
  type        = string
  description = "Bedrock Guardrail version (optional)"
  default     = ""
}

# ==================== OpenSearch Serverless (AOSS) ====================

variable "aoss_collection_endpoint" {
  type        = string
  description = "OpenSearch Serverless collection endpoint URL"
}

variable "aoss_collection_arn" {
  type        = string
  description = "OpenSearch Serverless collection ARN (for IAM policy)"
  default     = ""
}

# ==================== DynamoDB ====================

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for conversation logs"
  #default     = "RAG-ConversationLogs"
}

# ==================== Lambda Runtime Configuration ====================

variable "lambda_runtime" {
  type        = string
  default     = "python3.12"
  description = "Lambda runtime version"
}

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

# ==================== Lambda Layer ====================

variable "lambda_layer_name" {
  type        = string
  default     = "smart-rag-dependencies"
  description = "Name of the Lambda layer containing Python dependencies"
}

variable "use_existing_layer" {
  type        = bool
  default     = true
  description = "Set to false for initial apply before layer exists. Lambda will deploy without dependencies (placeholder only)"
}

# ==================== Authorizer Configuration ====================

variable "auth_token" {
  type        = string
  description = "Bearer token for API Gateway authorizer"
  sensitive   = true
}

# OIDC Configuration (uncomment if using OIDC/JWT)
# variable "oidc_issuer" {
#   type        = string
#   description = "OIDC issuer URL"
#   default     = ""
# }
#
# variable "oidc_audience" {
#   type        = string
#   description = "OIDC audience (client ID)"
#   default     = ""
# }

# ==================== Logging ====================

variable "log_level" {
  type        = string
  default     = "INFO"
  description = "Log level for Lambda functions (DEBUG, INFO, WARNING, ERROR)"
  
  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.log_level)
    error_message = "log_level must be one of: DEBUG, INFO, WARNING, ERROR"
  }
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "CloudWatch log retention period in days"
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch retention period"
  }
}

# ==================== Tags ====================

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}

# ==================== Optional: S3 Access ====================
# Uncomment if Lambda needs direct S3 access

# variable "s3_bucket_name" {
#   type        = string
#   description = "S3 bucket name if Lambda needs direct access"
#   default     = ""
# }

# ==================== Optional: Terraform-Managed Layer ====================
# Uncomment if you want Terraform to manage the layer

# variable "layer_zip_path" {
#   type        = string
#   description = "Path to Lambda layer ZIP file"
#   default     = ""
# }

variable "enable_guardrails" {
  type        = bool
  default     = true
  description = "Enable guardrails IAM policy for Lambda"
}