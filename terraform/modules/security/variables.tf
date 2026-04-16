variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "blocked_input_message" {
  description = "Message shown when input is blocked"
  type        = string
  default     = "I can only answer questions about data engineering and the analytics platform."
}

variable "blocked_output_message" {
  description = "Message shown when output is blocked"
  type        = string
  default     = "I cannot provide that response."
}

variable "content_filter_strength" {
  description = "Strength for content filters (NONE, LOW, MEDIUM, HIGH)"
  type        = string
  default     = "MEDIUM"

  validation {
    condition     = contains(["NONE", "LOW", "MEDIUM", "HIGH"], var.content_filter_strength)
    error_message = "content_filter_strength must be NONE, LOW, MEDIUM, or HIGH"
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}


# GitHub OIDC Variables

variable "create_oidc_provider" {
  description = "Create new OIDC provider (false if already exists in account)"
  type        = bool
  default     = false
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "terraform_lock_table" {
  description = "DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}