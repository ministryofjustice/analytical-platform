module "observability_platform_tenant" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.0.1"

  observability_platform_account_id = "915524366300"
  enable_xray                       = true
}
