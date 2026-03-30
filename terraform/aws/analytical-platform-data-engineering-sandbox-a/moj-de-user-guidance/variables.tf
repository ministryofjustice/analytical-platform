variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}
variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "project_name" {
  type    = string
  default = "moj-de-user-guidance"
}

variable "s3_bucket_name" {
  type    = string
  default = "moj-de-user-guidance"
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

variable "collection_name" {
  type    = string
  default = "moj-de-user-guidance-collection"
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

variable "kb_name" {
  type    = string
  default = "moj-de-user-guidance-kb"
}

variable "kb_description" {
  type    = string
  default = "Bedrock Knowledge Base for moj-de-user-guidance documents in S3"
}

variable "data_source_name" {
  type    = string
  default = "moj-de-user-guidance-s3"
}

variable "terraform_runner_principal_arn" {
  type        = string
  description = "IAM principal ARN used by Terraform runner to manage OpenSearch Serverless resources"
  default     = null
  nullable    = true
}

variable "max_context_tokens" {
  type        = number
  description = "Maximum context tokens for RAG"
  default     = 4000
}

variable "model_id" {
  type        = string
  description = "Bedrock Model ID"
  default     = "anthropic.claude-3-5-sonnet-20241022-v2:0"
}

variable "kb_id" {
  type        = string
  description = "Bedrock Knowledge Base ID"
  default     = ""
}