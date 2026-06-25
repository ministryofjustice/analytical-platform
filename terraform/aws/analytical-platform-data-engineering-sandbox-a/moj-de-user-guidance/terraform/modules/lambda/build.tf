# terraform/modules/lambda/build.tf
# Builds layer + function + authorizer packages during `terraform apply`
# Replaces: create_lambda_layer.py + deploy_lambda.py manual steps

locals {
  build_dir          = "${path.module}/build"
  layer_build_dir    = "${local.build_dir}/layer"      # contains python/
  function_build_dir = "${local.build_dir}/function"

  function_source_files = toset(concat(
    # Top-level files (only include if they exist)
    [for f in ["lambda_handler.py", "config.py"] : f if fileexists("${var.source_dir}/${f}")],
    # KB catalog
    fileexists("${var.source_dir}/data/kb_catalog.json") ? ["data/kb_catalog.json"] : [],
    # All Python files under helpers/
    [for f in fileset(var.source_dir, "helpers/**/*.py") : f],
  ))

  # Hash all Python sources so any code change forces a rebuild + redeploy
  function_source_hash = sha1(join("", [
    for f in local.function_source_files :
    filesha1("${var.source_dir}/${f}")
  ]))

  requirements_hash = filesha1(var.requirements_lambda_path)
}

# ==================== STEP 1: Build the dependency layer ====================
# Ports create_lambda_layer.py logic into Terraform (same pip flags).
resource "null_resource" "build_layer" {
  triggers = {
    requirements = local.requirements_hash
    runtime      = var.lambda_runtime
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      rm -rf "${local.layer_build_dir}"
      mkdir -p "${local.layer_build_dir}/python"
      python3 -m pip install \
        -r "${var.requirements_lambda_path}" \
        -t "${local.layer_build_dir}/python" \
        --platform manylinux2014_x86_64 \
        --only-binary=:all: \
        --python-version ${replace(var.lambda_runtime, "python", "")} \
        --no-cache-dir
      # Strip bloat to stay under 250MB unzipped
      find "${local.layer_build_dir}/python" -type d -name "__pycache__" -prune -exec rm -rf {} + || true
      find "${local.layer_build_dir}/python" -type d -name "tests" -prune -exec rm -rf {} + || true
    EOT
  }
}

# ==================== STEP 2: Stage function code ====================
resource "null_resource" "build_function" {
  triggers = {
    source = local.function_source_hash
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      rm -rf "${local.function_build_dir}"
      mkdir -p "${local.function_build_dir}/data"
      cp "${var.source_dir}/lambda_handler.py" "${local.function_build_dir}/"
      cp "${var.source_dir}/config.py"         "${local.function_build_dir}/"
      cp -R "${var.source_dir}/helpers"        "${local.function_build_dir}/helpers"
      cp "${var.source_dir}/data/kb_catalog.json" "${local.function_build_dir}/data/kb_catalog.json"
      find "${local.function_build_dir}" -type d -name "__pycache__" -prune -exec rm -rf {} + || true
      find "${local.function_build_dir}" -type f -name "*.pyc" -delete || true
    EOT
  }
}

# ==================== STEP 3: Zip everything ====================
data "archive_file" "layer" {
  type        = "zip"
  source_dir  = local.layer_build_dir          # zips python/...
  output_path = "${local.build_dir}/layer.zip"
  depends_on  = [null_resource.build_layer]
}

data "archive_file" "function" {
  type        = "zip"
  source_dir  = local.function_build_dir
  output_path = "${local.build_dir}/function.zip"
  depends_on  = [null_resource.build_function]
}

data "archive_file" "authorizer" {
  type        = "zip"
  source_file = "${var.source_dir}/deployment/lambda_authorizer.py"
  output_path = "${local.build_dir}/authorizer.zip"
}

# ==================== STEP 4: Upload to S3 (bucket #3, created in artifacts_bucket.tf) ====================
resource "aws_s3_object" "layer" {
  bucket = aws_s3_bucket.artifacts.id
  key    = "layers/dependencies-${data.archive_file.layer.output_md5}.zip"
  source = data.archive_file.layer.output_path
  etag   = data.archive_file.layer.output_md5

  depends_on = [null_resource.build_layer]
}

resource "aws_s3_object" "function" {
  bucket = aws_s3_bucket.artifacts.id
  key    = "functions/smart-rag-${data.archive_file.function.output_md5}.zip"
  source = data.archive_file.function.output_path
  etag   = data.archive_file.function.output_md5

  depends_on = [null_resource.build_function]
}

resource "aws_s3_object" "authorizer" {
  bucket = aws_s3_bucket.artifacts.id
  key    = "functions/authorizer-${data.archive_file.authorizer.output_md5}.zip"
  source = data.archive_file.authorizer.output_path
  etag   = data.archive_file.authorizer.output_md5
}

# ==================== STEP 5: Layer resource from S3 ====================
resource "aws_lambda_layer_version" "dependencies" {
  layer_name               = "${var.project_name}-${var.environment}-dependencies"
  description              = "Python dependencies for SmartRAG (Terraform-built)"
  compatible_runtimes      = [var.lambda_runtime]
  compatible_architectures = ["x86_64"]

  s3_bucket        = aws_s3_bucket.artifacts.id
  s3_key           = aws_s3_object.layer.key
  source_code_hash = data.archive_file.layer.output_base64sha256
}
