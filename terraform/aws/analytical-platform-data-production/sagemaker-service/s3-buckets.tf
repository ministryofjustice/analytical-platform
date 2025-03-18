data "aws_iam_policy_document" "sagemaker_ai_probation_search_models_s3" {
  statement {
    sid     = "AllowSageMakerAIExecutionRolesListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::381491960855:role/hmpps-probation-search-dev-sagemaker-exec-role",
        "arn:aws:iam::992382429243:role/hmpps-probation-search-preprod-sagemaker-exec-role",
        "arn:aws:iam::992382429243:role/hmpps-probation-search-prod-sagemaker-exec-role"
      ]
    }
    resources = ["arn:aws:s3:::mojap-data-production-sagemaker-ai-probation-search-models"]
  }
  statement {
    sid     = "AllowSageMakerAIExecutionRolesGetObject"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::381491960855:role/hmpps-probation-search-dev-sagemaker-exec-role",
        "arn:aws:iam::992382429243:role/hmpps-probation-search-preprod-sagemaker-exec-role",
        "arn:aws:iam::992382429243:role/hmpps-probation-search-prod-sagemaker-exec-role"
      ]
    }
    resources = ["arn:aws:s3:::mojap-data-production-sagemaker-ai-probation-search-models/*"]
  }
}

#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "sagemaker_ai_probation_search_models_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket = "mojap-data-production-sagemaker-ai-probation-search-models"

  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.sagemaker_ai_probation_search_models_s3.json

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.sagemaker_ai_probation_search_models_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
