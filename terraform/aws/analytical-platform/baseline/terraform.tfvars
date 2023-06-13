account_ids = {
  data-development            = "803963757240"
  data-engineering-production = "189157455002"
  data-engineering-sandbox-a  = "684969100054"
  data-production             = "593291632749"
  development                 = "525294151996"
  landing-production          = "335823981503"
  management-production       = "042130406152"
  production                  = "312423030077"
}

pagerduty_services = {
  data-development = {
    guardduty     = "data-platform-security"
    cost-explorer = "data-platform"
  }
  data-engineering-production = {
    guardduty     = "data-platform-security"
    cost-explorer = "data-platform"
  }
  data-engineering-sandbox-a = {
    guardduty     = "data-platform-security"
    cost-explorer = "data-platform"
  }
  data-production = {
    guardduty     = "data-platform-security"
    cost-explorer = "data-platform"
  }
  development = {
    guardduty     = "data-platform-security"
    cost-explorer = "data-platform"
  }
  landing-production = {
    guardduty     = "data-platform-security"
    cost-explorer = "data-platform"
  }
  management-production = {
    guardduty     = "data-platform-security"
    cost-explorer = "data-platform"
  }
  production = {
    guardduty     = "data-platform-security"
    cost-explorer = "data-platform"
  }
}

tags = {
  business-unit          = "Platforms"
  application            = "Analytical Platform"
  component              = "Infrastructure baseline"
  is-production          = "true"
  owner                  = "analytical-platform:analytics-platform-tech@digital.justice.gov.uk"
  infrastructure-support = "analytical-platform:analytics-platform-tech@digital.justice.gov.uk"
  source-code            = "github.com/ministryofjustice/analytical-platform-infrastructure"
}
