# terraform/environments/dev/terraform.tfvars

# ==================== General ====================
region       = "eu-west-2"
project_name = "moj-de-user-guidance"
environment  = "dev"

# ==================== Bedrock KB ====================
s3_bucket_name      = "moj-de-user-guidance-kb-dev"
skip_kb_creation    = true
skip_index_creation = true
create_s3_bucket    = false

# ==================== Lambda ====================
lambda_timeout    = 30
lambda_memory     = 512
lambda_runtime    = "python3.12"

bedrock_model_id   = "anthropic.claude-3-sonnet-20240229-v1:0"
max_context_tokens = 4096

# ==================== API Gateway ====================
api_stage_name = "dev"

# ==================== Database (DynamoDB) ====================
dynamodb_table_name     = "RAG-ConversationLogs"
dynamodb_pitr_enabled   = true
dynamodb_stream_enabled = true

# ==================== Security (Guardrails) ====================
guardrail_filter_strength = "MEDIUM"

# ==================== GitHub OIDC ====================
github_org  = "ministryofjustice"
github_repo = "analytical-platform"

# ==================== Lambda Artifacts ====================
artifacts_bucket = "moj-de-genai-dev-lambda-artifacts"

# ==================== Knowledge Base ====================
kb_id = "5ZPAUF2C5A"
