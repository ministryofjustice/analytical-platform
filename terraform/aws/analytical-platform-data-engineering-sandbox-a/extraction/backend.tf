terraform {
  backend "s3" {
    acl     = "private"
    bucket  = "probation-terraform-state-sandbox-test"
    encrypt = true
    key     = "extraction/terraformv2.tfstate"
    region  = "eu-west-1"
    # TODO: Add dynamodb lock table
  }
}

