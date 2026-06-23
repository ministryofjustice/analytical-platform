# terraform/modules/lambda/cloudwatch.tf
# CloudWatch Log Groups for Lambda functions
#
# Pre-creating log groups allows:
# - Control over retention period
# - Consistent naming
# - Proper tagging

# ==================== Main Lambda Log Group ====================

resource "aws_cloudwatch_log_group" "smart_rag" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-smart-rag-logs"
    Description = "Logs for SmartRAG main Lambda function"
  })
}

# ==================== Authorizer Lambda Log Group ====================

resource "aws_cloudwatch_log_group" "authorizer" {
  name              = "/aws/lambda/${local.authorizer_function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-authorizer-logs"
    Description = "Logs for SmartRAG API Gateway authorizer"
  })
}
