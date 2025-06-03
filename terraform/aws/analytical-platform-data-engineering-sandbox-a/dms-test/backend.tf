terraform {
  backend "s3" {
    acl     = "private"
    bucket  = "probation-terraform-state-sandbox-test"
    encrypt = true
    key     = "dms-test/terraform.tfstate"
    region  = "eu-west-1"
    # TODO: Add dynamodb lock table
  }
}
