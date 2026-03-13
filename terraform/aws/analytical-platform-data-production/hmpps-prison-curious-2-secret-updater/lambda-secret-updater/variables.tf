variable "lambda_name" {
  type        = string
  description = "Name of the Lambda function to create."
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket containing the SAS token file."
}

variable "object_key" {
  type        = string
  description = "Full S3 object key path to sas_token_info.txt."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the Lambda function should run."
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block of the VPC where the Lambda function runs."
}

variable "vpc_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Lambda ENIs."
}

variable "secret_name" {
  type        = string
  description = "Name of the Secrets Manager secret to update (without ARN)."
}

variable "delete_after_processing" {
  type        = bool
  description = "Whether to delete the S3 object after successfully updating the secret."
  default     = true
}

variable "reserved_concurrent_executions" {
  type        = number
  description = "Amount of reserved concurrent executions for the Lambda function."
  default     = 5
}
