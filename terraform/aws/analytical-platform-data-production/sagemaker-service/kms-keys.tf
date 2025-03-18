module "sagemaker_ai_probation_search_models_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/sagemaker-ai-probation-search-models"]
  description           = "SageMaker AI Probation Search Models KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}
