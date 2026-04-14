# terraform/environments/dev/main.tf

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

# ==================== Bedrock Knowledge Base Module ====================

module "bedrock_kb" {
  source = "../../modules/bedrock-kb"

  region               = var.region
  project_name         = var.project_name
  environment          = var.environment
  s3_bucket_name       = var.s3_bucket_name
  skip_index_creation  = var.skip_index_creation
  skip_kb_creation     = var.skip_kb_creation
  create_s3_bucket     = var.create_s3_bucket
  
  tags = {
    Owner      = "data-engineering"
    CostCenter = "de-genai"
  }
}

# ==================== Lambda Module ====================

module "lambda" {
  source = "../../modules/lambda"

  region       = var.region
  project_name = var.project_name
  environment  = var.environment

  # Lambda Configuration
  lambda_timeout    = var.lambda_timeout
  lambda_memory     = var.lambda_memory
  lambda_runtime    = var.lambda_runtime
  lambda_layer_name = var.lambda_layer_name
  lambda_role_name  = var.lambda_role_name

  # Bedrock Knowledge Base
  kb_id                    = module.bedrock_kb.knowledge_base_id
  model_id                 = var.bedrock_model_id
  max_context_tokens       = var.max_context_tokens
  aoss_collection_endpoint = module.bedrock_kb.collection_endpoint

  # Authentication
  auth_token = var.auth_token

  tags = {
    Owner      = "data-engineering"
    CostCenter = "de-genai"
  }

  depends_on = [module.bedrock_kb]
}

# ==================== API Gateway Module ====================

module "api_gateway" {
  source = "../../modules/api-gateway"

  region       = var.region
  project_name = var.project_name
  environment  = var.environment

  # Lambda Integration
  smart_rag_function_arn   = module.lambda.smart_rag_function_arn
  smart_rag_function_name  = module.lambda.smart_rag_function_name
  authorizer_function_arn  = module.lambda.authorizer_function_arn
  authorizer_function_name = module.lambda.authorizer_function_name

  # Authentication
  auth_token = var.auth_token

  # Stage Configuration
  stage_name = var.api_stage_name

  tags = {
    Owner      = "data-engineering"
    CostCenter = "de-genai"
  }

  depends_on = [module.lambda]
}