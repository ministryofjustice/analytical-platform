module "sagemaker_ai_probation_search_models_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  aliases               = ["s3/sagemaker-ai-probation-search-models"]
  description           = "SageMaker AI Probation Search Models KMS Key"
  enable_default_policy = true

  key_statements = [
    {
      sid = "AllowSageMakerAIExecutionRoles"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      principals = [
        {
          type = "AWS"
          identifiers = [
            "arn:aws:iam::381491960855:role/hmpps-probation-search-dev-sagemaker-exec-role",
            "arn:aws:iam::992382429243:role/hmpps-probation-search-preprod-sagemaker-exec-role",
            "arn:aws:iam::992382429243:role/hmpps-probation-search-prod-sagemaker-exec-role"
          ]
        }
      ]
      resources = ["*"]
    }
  ]

  deletion_window_in_days = 7
}
