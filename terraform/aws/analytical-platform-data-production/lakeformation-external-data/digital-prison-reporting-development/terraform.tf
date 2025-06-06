
provider "aws" {
  alias  = "digital_prison_reporting_dev_eu_west_2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["digital-prison-reporting-development"]}:role/analytical-platform-data-production-share-role"
  }
  default_tags {
    tags = var.tags
  }
}
