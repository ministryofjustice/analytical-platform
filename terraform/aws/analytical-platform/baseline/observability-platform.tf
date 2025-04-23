##################################################
# Data Development
##################################################

module "data_development_observability_platform" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  providers = {
    aws = aws.analytical-platform-data-development-eu-west-2
  }

  observability_platform_account_id = var.observability_platform_account_ids["production"]
}

module "data_development_analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=ccefcbdcecd3c5dfd25474b66ac06a58bd810928" # 2.0.0

  providers = {
    aws = aws.analytical-platform-data-development-eu-west-2
  }
}

##################################################
# Data Engineering Production
##################################################

module "data_engineering_production_observability_platform" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  providers = {
    aws = aws.analytical-platform-data-engineering-production-eu-west-2
  }

  observability_platform_account_id = var.observability_platform_account_ids["production"]
}

module "data_engineering_production_analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=ccefcbdcecd3c5dfd25474b66ac06a58bd810928" # 2.0.0

  providers = {
    aws = aws.analytical-platform-data-engineering-production-eu-west-2
  }
}

##################################################
# Data Engineering Sandbox A
##################################################

module "data_engineering_sandbox_a_observability_platform" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  providers = {
    aws = aws.analytical-platform-data-engineering-sandbox-a-eu-west-2
  }

  observability_platform_account_id = var.observability_platform_account_ids["production"]
}

module "data_engineering_sandbox_a_analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=ccefcbdcecd3c5dfd25474b66ac06a58bd810928" # 2.0.0

  providers = {
    aws = aws.analytical-platform-data-engineering-sandbox-a-eu-west-2
  }
}

##################################################
# Data Production
##################################################

module "data_production_observability_platform" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  providers = {
    aws = aws.analytical-platform-data-production-eu-west-2
  }

  observability_platform_account_id = var.observability_platform_account_ids["production"]
}

module "data_production_analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=ccefcbdcecd3c5dfd25474b66ac06a58bd810928" # 2.0.0

  providers = {
    aws = aws.analytical-platform-data-production-eu-west-2
  }
}

##################################################
# Development
##################################################

# This is done in terraform/aws/analytical-platform-development/cluster

##################################################
# Landing Production
##################################################

module "landing_production_observability_platform" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  providers = {
    aws = aws.analytical-platform-landing-production-eu-west-2
  }

  observability_platform_account_id = var.observability_platform_account_ids["production"]
}

module "landing_production_analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=ccefcbdcecd3c5dfd25474b66ac06a58bd810928" # 2.0.0

  providers = {
    aws = aws.analytical-platform-landing-production-eu-west-2
  }
}

##################################################
# Management Production
##################################################

module "management_production_observability_platform" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "ministryofjustice/observability-platform-tenant/aws"
  version = "1.2.0"

  providers = {
    aws = aws.analytical-platform-management-production-eu-west-2
  }

  observability_platform_account_id = var.observability_platform_account_ids["production"]
}

module "management_production_analytical_platform_observability" {
  source = "github.com/ministryofjustice/terraform-aws-analytical-platform-observability?ref=ccefcbdcecd3c5dfd25474b66ac06a58bd810928" # 2.0.0

  providers = {
    aws = aws.analytical-platform-management-production-eu-west-2
  }
}

##################################################
# Production
##################################################

# This is done in terraform/aws/analytical-platform-production/cluster
