module "data_engineering_sandbox_a_observability_platform" {
  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  providers = {
    aws = aws.analytical-platform-data-engineering-sandbox-a-eu-west-2
  }

  observability_platform_account_id = var.observability_platform_account_ids["development"]
}
