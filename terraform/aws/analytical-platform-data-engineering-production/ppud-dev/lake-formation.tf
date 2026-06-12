provider "aws" {
  alias  = "lakeformation_eu_west_1"
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  alias  = "consumer_593291632749"
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::593291632749:role/GlobalGitHubActionAdmin"
  }
}
