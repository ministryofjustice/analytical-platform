provider "aws" {
  default_tags {
    tags = {
      business-unit    = "Platforms"
      application      = "Data Engineering"
      environment-name = "sandbox"
      is-production    = "False"
      owner            = "Data Engineering:dataengineering@digital.justice.gov.uk"
    }
  }
}

