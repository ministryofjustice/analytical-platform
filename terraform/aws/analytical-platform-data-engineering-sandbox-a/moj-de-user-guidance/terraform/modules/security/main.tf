################################################################################
# Bedrock Guardrail
################################################################################


terraform {
  required_version = ">= 1.5.0"
}


resource "aws_bedrock_guardrail" "this" {
  name                      = "${var.project_name}-${var.environment}-content-filter"
  description               = "Content filtering for Smart RAG chatbot - ${var.environment}"
  blocked_input_messaging   = var.blocked_input_message
  blocked_outputs_messaging = var.blocked_output_message

  # Content Policy - Filter harmful content
  content_policy_config {
    filters_config {
      type            = "HATE"
      input_strength  = var.content_filter_strength
      output_strength = var.content_filter_strength
    }
    filters_config {
      type            = "VIOLENCE"
      input_strength  = var.content_filter_strength
      output_strength = var.content_filter_strength
    }
    filters_config {
      type            = "SEXUAL"
      input_strength  = var.content_filter_strength
      output_strength = var.content_filter_strength
    }
    filters_config {
      type            = "MISCONDUCT"
      input_strength  = var.content_filter_strength
      output_strength = var.content_filter_strength
    }
    filters_config {
      type            = "INSULTS"
      input_strength  = var.content_filter_strength
      output_strength = var.content_filter_strength
    }
    filters_config {
      type            = "PROMPT_ATTACK"
      input_strength  = var.content_filter_strength
      output_strength = "NONE"
    }
  }

  # Sensitive Information Policy - Block PII
  sensitive_information_policy_config {
    pii_entities_config {
      type   = "EMAIL"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "PHONE"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "US_SOCIAL_SECURITY_NUMBER"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "CREDIT_DEBIT_CARD_NUMBER"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "UK_NATIONAL_INSURANCE_NUMBER"
      action = "BLOCK"
    }
  }

  # Topic Policy - Deny off-topic questions
  topic_policy_config {
    topics_config {
      name       = "Off-Topic"
      definition = "Questions not related to data engineering, analytics, databases, SQL, Python, R, data tools, or technical documentation"
      examples = [
        "What is the weather today?",
        "Tell me a joke",
        "Who won the game?"
      ]
      type = "DENY"
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-guardrail"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

################################################################################
# Guardrail Version
################################################################################

resource "aws_bedrock_guardrail_version" "this" {
  guardrail_arn = aws_bedrock_guardrail.this.guardrail_arn
  description   = "Production version managed by Terraform"
}
