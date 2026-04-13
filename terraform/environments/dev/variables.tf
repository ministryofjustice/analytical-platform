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