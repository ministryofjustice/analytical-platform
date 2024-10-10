module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  observability_platform_account_id = "319748487814" # observability-platform-production
  enable_prometheus                 = true
  additional_policies = {
    managed_prometheus_kms_access = module.managed_prometheus_kms_access_iam_policy.arn
  }
}
