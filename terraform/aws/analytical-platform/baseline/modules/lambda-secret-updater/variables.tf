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

variable "secret_name" {
  type        = string
  description = "Name of the Secrets Manager secret to update (without ARN)."
}

variable "delete_after_processing" {
  type        = bool
  description = "Whether to delete the S3 object after successfully updating the secret."
  default     = true
}