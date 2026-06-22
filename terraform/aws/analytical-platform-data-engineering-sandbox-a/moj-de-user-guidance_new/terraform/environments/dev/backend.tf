# Memory
terraform {
  backend "s3" {
    bucket         = "moj-de-genai-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "moj-de-genai-terraform-state"
    encrypt        = true
  }
}
