##################################################
# General
##################################################

account_ids = {
  analytical-platform-data-production       = "593291632749"
  analytical-platform-management-production = "042130406152"
  cloud-platform                            = "754256621582"
}

data_buckets = [
  "moj-reg-dev-curated",
  "moj-reg-preprod-curated",
  "moj-reg-prod-curated"
]

athena_query_result_buckets = ["aws-athena-query-results-593291632749-eu-west-1"]

datahub_cp_irsa_role_names = {
  dev     = "cloud-platform-irsa-33e75989394c3a08-live",
  preprod = "cloud-platform-irsa-fe098636951cc219-live"
}

tags = {
  business-unit          = "Platforms"
  application            = "Analytical Platform"
  component              = "Environment"
  environment            = "production"
  is-production          = "true"
  owner                  = "analytical-platform:analytics-platform-tech@digital.justice.gov.uk"
  infrastructure-support = "analytical-platform:analytics-platform-tech@digital.justice.gov.uk"
  source-code            = "github.com/ministryofjustice/analytical-platform-infrastructure"
}
