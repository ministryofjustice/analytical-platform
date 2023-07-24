module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"

  name = "control-panel-sqs"

  tags = {
    Environment = "dev"
  }
}