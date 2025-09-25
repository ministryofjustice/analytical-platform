variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}
variable "database_subnet_ids" {
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
}
variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encrypting the RDS instance"
  type        = string
}
variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}
