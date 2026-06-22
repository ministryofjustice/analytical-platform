# Security Module

Manages Bedrock Guardrails for Smart RAG chatbot.

## Resources Created

- **Bedrock Guardrail** - Content filtering, PII protection, topic filtering
- **Guardrail Version** - Published version for production use

## Usage

```hcl
module "security" {
  source = "../../modules/security"

  project_name = "genai-data-eng"
  environment  = "dev"

  tags = local.common_tags
}
