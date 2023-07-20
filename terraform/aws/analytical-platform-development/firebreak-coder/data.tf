data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_route53_zone" "data_platform_moj_woffenden_dev" {
  name = "data-platform.moj.woffenden.dev"
}

data "aws_vpcs" "open_metadata" {
  tags = {
    Name = "open-metadata"
  }
}

data "aws_vpc" "open_metadata" {
  id = data.aws_vpcs.open_metadata.ids[0]
}

data "aws_eks_cluster" "open_metadata" {
  name = "open-metadata"
}
