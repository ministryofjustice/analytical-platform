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
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
