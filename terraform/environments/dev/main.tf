terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "awscc" {
  region = var.region
}

module "bedrock_kb" {
  source = "../../modules/bedrock-kb"

  region         = var.region
  project_name   = var.project_name
  environment    = var.environment
  s3_bucket_name = var.s3_bucket_name
  skip_index_creation  = var.skip_index_creation    # Until SCP is fixed
  skip_kb_creation    = var.skip_kb_creation
  create_s3_bucket    = var.create_s3_bucket    
  
  tags = {
    Owner      = "data-engineering"
    CostCenter = "de-genai"
  }
}
