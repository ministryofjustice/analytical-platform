# PREREQUISITE: Layer must exist before terraform apply (unless use_existing_layer = false)
# Create it with: python deployment/create_lambda_layer.py
#
# For initial apply without layer:
#   terraform apply -var="use_existing_layer=false"
# Then create layer and re-apply:
#   python deployment/create_lambda_layer.py
#   terraform apply

# ==================== Data Source for Existing Layer ====================
# Looks up the latest version of the dependencies layer

data "aws_lambda_layer_version" "dependencies" {
  count              = var.use_existing_layer ? 1 : 0
  layer_name         = var.lambda_layer_name
  compatible_runtime = var.lambda_runtime
}

# ==================== Alternative: Terraform-Managed Layer ====================
# Uncomment this if you want Terraform to create/manage the layer
# Requires the layer ZIP to be built by CI/CD

# resource "aws_lambda_layer_version" "dependencies" {
#   layer_name          = "${var.project_name}-${var.environment}-dependencies"
#   description         = "Python dependencies for SmartRAG Lambda"
#   compatible_runtimes = [var.lambda_runtime]
#   
#   # Option 1: Local file (built by CI/CD)
#   filename            = var.layer_zip_path
#   source_code_hash    = filebase64sha256(var.layer_zip_path)
#   
#   # Option 2: S3 (for larger layers)
#   # s3_bucket         = var.artifacts_bucket
#   # s3_key            = "layers/${var.project_name}-dependencies.zip"
# }
