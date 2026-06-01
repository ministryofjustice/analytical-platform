##################################################
# General
##################################################
account_ids = {
  analytical-platform-data-engineering-sandbox-a = "684969100054"
  analytical-platform-management-production      = "042130406152"
}

tags = {
  business-unit        = "HMPPS"
  application          = "Data Engineering"
  component            = "Data Engineering lake_formation"
  environment          = "sandbox"
  is-production        = "false"
  owner                = "Data Engineering:dataengineering@digital.justice.gov.uk"
  source-code          = "https://github.com/ministryofjustice/analytical-platform/tree/rds-export-test/terraform/aws/analytical-platform-data-engineering-sandbox-a/lake_formation_de_access_replica"
  de-sandbox-nuke-keep = "true"
}

source_role_arn = 
destination_role_arn = 