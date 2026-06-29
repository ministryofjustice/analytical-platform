# modules/api-gateway/variables.tf

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

# ==================== Lambda Integration ====================

variable "smart_rag_function_arn" {
  type        = string
  description = "ARN of main SmartRAG Lambda function"
}

variable "smart_rag_function_name" {
  type        = string
  description = "Name of main SmartRAG Lambda function"
}

variable "authorizer_function_arn" {
  type        = string
  description = "ARN of authorizer Lambda function"
}

variable "authorizer_function_name" {
  type        = string
  description = "Name of authorizer Lambda function"
}

# ==================== Authentication ====================

variable "auth_token" {
  type        = string
  description = "Bearer token for API authentication (empty = no auth)"
  default     = ""
  sensitive   = true
}

variable "authorizer_cache_ttl" {
  type        = number
  default     = 0
  description = "Authorizer result cache TTL in seconds (0 = no caching)"
}

# ==================== Stage Config ====================

variable "stage_name" {
  type        = string
  default     = ""
  description = "API Gateway stage name (defaults to environment if empty)"
}

# ==================== Tags ====================
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
