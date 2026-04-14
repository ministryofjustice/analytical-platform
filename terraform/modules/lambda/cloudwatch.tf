# Log groups
# modules/lambda/cloudwatch.tf
# Log groups for Lambda functions

# ==================== Main Lambda Log Group ====================

resource "aws_cloudwatch_log_group" "smart_rag" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-smart-rag"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-smart-rag-logs"
  })
}

# ==================== Authorizer Lambda Log Group ====================

resource "aws_cloudwatch_log_group" "authorizer" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-smart-rag-authorizer"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-authorizer-logs"
  })
}
