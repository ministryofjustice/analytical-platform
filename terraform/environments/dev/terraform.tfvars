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
lambda_layer_name = "smart-rag-dependencies"
#lambda_role_name  = "lambda_smart_rag-role-o0zb4frf"
use_existing_layer = true  # Set to true after creating layer

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

# ==================== Secrets (Set via GitHub Actions) ====================
auth_token = "abc123XYZ_generated_token_here_456def"

github_org  = "ministryofjustice"
github_repo = "MOJ-genai-app"

kb_id = "QA1AIJHQIJ"
