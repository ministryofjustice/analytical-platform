#trivy:ignore:avd-aws-0066:X-Ray is not required for this service
module "lambda_smart_rag" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/lambda/aws"
  version = "8.1.0"

  function_name = "lambda_smart_rag"
  description   = "Smart RAG Lambda function for MOJ DE User Guidance"
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512
  architectures = ["x86_64"]

  source_path                  = "${path.module}/lambda-functions/smart-rag"
  trigger_on_package_timestamp = false
  store_on_s3                  = false

  create_role = false
  lambda_role = aws_iam_role.lambda_smart_rag.arn

  environment_variables = {
    KB_ID               = var.kb_id
    MODEL_ID            = var.model_id
    BEDROCK_REGION      = "eu-west-1"
    MAX_CONTEXT_TOKENS  = var.max_context_tokens
    BUCKET_NAME         = module.moj_de_user_guidance.s3_bucket_id
  }
}
