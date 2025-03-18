module "sagemaker_ai_probation_search_models_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket = "mojap-data-production-sagemaker-ai-probation-search-models"

  force_destroy = true

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
