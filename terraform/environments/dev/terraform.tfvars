# terraform/environments/dev/terraform.tfvars

# ==================== General ====================
region       = "eu-west-2"
project_name = "moj-de-user-guidance"
environment  = "dev"

# ==================== Bedrock KB ====================
s3_bucket_name       = "moj-de-user-guidance-kb-dev"
skip_kb_creation     = true
skip_index_creation  = true   # flip to false once SCP is fixed
create_s3_bucket     = false  # Using existing bucket

# ==================== Lambda ====================
lambda_timeout    = 30
lambda_memory     = 512
lambda_runtime    = "python3.12"
lambda_layer_name = "smart-rag-dependencies"
lambda_role_name  = "lambda_smart_rag-role-o0zb4frf"  # Your existing role

bedrock_model_id   = "anthropic.claude-3-sonnet-20240229-v1:0"
max_context_tokens = 4096

# ==================== API Gateway ====================
api_stage_name = "prod"

# ==================== Secrets (Set via GitHub Actions) ====================
# TF_VAR_auth_token (from GitHub Secrets)
# TF_VAR_github_role_arn (from GitHub Secrets)