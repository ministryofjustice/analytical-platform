variable "region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "s3_inclusion_prefixes" {
  type    = list(string)
  default = []
}

variable "embedding_model_id" {
  type    = string
  default = "amazon.titan-embed-text-v2:0"
}

variable "vector_dimensions" {
  type    = number
  default = 1024
}

variable "index_name" {
  type    = string
  default = "bedrock-knowledge-base-default-index"
}

variable "vector_field" {
  type    = string
  default = "bedrock-knowledge-base-default-vector"
}

variable "text_field" {
  type    = string
  default = "AMAZON_BEDROCK_TEXT"
}

variable "metadata_field" {
  type    = string
  default = "AMAZON_BEDROCK_METADATA"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}

variable "skip_kb_creation" {
  type        = bool
  default     = false
  description = "Skip KB and data source creation when index doesn't exist yet"
}

variable "skip_index_creation" {
  type        = bool
  default     = false
  description = "Skip index creation when SCP blocks aoss:APIAccessAll"
}

variable "create_s3_bucket" {
  type        = bool
  default     = true
  description = "Set to false if S3 bucket already exists"
}

variable "lambda_role_arn" {
  type        = string
  default     = null
  description = "Lambda execution role ARN to grant AOSS access"
}
