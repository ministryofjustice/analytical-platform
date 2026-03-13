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
