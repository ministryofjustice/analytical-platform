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

# ==================== Data Sources ====================

data "aws_caller_identity" "current" {}

# ==================== Local Values ====================

locals {
  common_tags = {
    Owner       = "data-engineering"
    CostCenter  = "de-genai"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ==================== Database Module (DynamoDB) ====================

module "database" {
  source = "../../modules/database"

  project_name = var.project_name
  environment  = var.environment

  # Optional overrides
  table_name             = var.dynamodb_table_name
  point_in_time_recovery = var.dynamodb_pitr_enabled
  stream_enabled         = var.dynamodb_stream_enabled

  tags = local.common_tags
}

# ==================== Security Module (Guardrails) ====================

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment

  # Optional overrides
  content_filter_strength = var.guardrail_filter_strength

  # Missing OIDC variables
  create_oidc_provider   = false  # provider already exists
  github_org             = var.github_org
  github_repo            = var.github_repo
  terraform_state_bucket = "moj-de-genai-terraform-state"
  terraform_lock_table   = "moj-de-genai-terraform-state"

  tags = local.common_tags
}

# ==================== Bedrock Knowledge Base Module ====================

module "bedrock_kb" {
  source = "../../modules/bedrock-kb"

  region              = var.region
  project_name        = var.project_name
  environment         = var.environment
  s3_bucket_name      = var.s3_bucket_name
  skip_index_creation = var.skip_index_creation
  skip_kb_creation    = var.skip_kb_creation
  create_s3_bucket    = var.create_s3_bucket

  # Add Lambda role to AOSS data access policy
  lambda_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-lambda-execution-role"

  tags = local.common_tags
}

# ==================== Lambda Module ====================

module "lambda" {
  source = "../../modules/lambda"

  region       = var.region
  project_name = var.project_name
  environment  = "dev"

  # Lambda Configuration
  lambda_timeout    = var.lambda_timeout
  lambda_memory     = var.lambda_memory
  lambda_runtime    = var.lambda_runtime
  lambda_layer_name = var.lambda_layer_name
  use_existing_layer = var.use_existing_layer

  # Bedrock Knowledge Base
  kb_id = var.kb_id
  model_id                 = var.bedrock_model_id
  max_context_tokens       = var.max_context_tokens
  aoss_collection_endpoint = module.bedrock_kb.collection_endpoint
  aoss_collection_arn      = module.bedrock_kb.collection_arn

  # DynamoDB
  dynamodb_table_name = module.database.table_name

  # Guardrails
  guardrail_id      = module.security.guardrail_id
  guardrail_version = module.security.guardrail_version
  enable_guardrails = true    

  # Authentication
  auth_token = var.auth_token

  tags = local.common_tags

  depends_on = [
    module.bedrock_kb,
    module.database,
    module.security
  ]
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

  tags = local.common_tags

  depends_on = [module.lambda]
}