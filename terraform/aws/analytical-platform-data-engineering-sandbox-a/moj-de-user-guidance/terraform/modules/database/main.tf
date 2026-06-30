# modules/database/main.tf


terraform {
  required_version = ">= 1.5.0"
}

# DynamoDB table for RAG conversation logging

################################################################################
# DynamoDB Table
################################################################################

resource "aws_dynamodb_table" "conversation_logs" {
  name         = "${var.project_name}-${var.environment}-${var.table_name}"
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing for POC

  # Primary Key
  hash_key  = "request_id" # Partition key
  range_key = "timestamp"  # Sort key

  # Attribute Definitions (only for keys and GSI)
  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "session_id"
    type = "S"
  }

  # GSI: Query conversations by user
  global_secondary_index {
    name            = "UserTimeIndex"
    hash_key        = "user_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # GSI: Query conversations by session
  global_secondary_index {
    name            = "SessionIndex"
    hash_key        = "session_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # TTL - 90 days retention
  ttl {
    enabled        = true
    attribute_name = var.ttl_attribute
  }

  # Point-in-Time Recovery
  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  # DynamoDB Streams
  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? var.stream_view_type : null

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${var.table_name}"
    Environment = var.environment
    Application = "RAG-Chatbot"
    Purpose     = "ConversationLogging"
    ManagedBy   = "terraform"
  })
}
