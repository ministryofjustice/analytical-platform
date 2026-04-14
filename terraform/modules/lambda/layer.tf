# Reference existing Lambda layer (created by create_lambda_layer.py)

# ==================== Data Source for Existing Layer ====================

data "aws_lambda_layer_version" "dependencies" {
  layer_name         = var.lambda_layer_name
  compatible_runtime = var.lambda_runtime
}