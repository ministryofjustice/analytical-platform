data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_region" "current" {}

data "aws_vpc_endpoint" "network_firewall" {
  for_each = local.environment_configuration.vpc_subnets.firewall
  vpc_id   = aws_vpc.main.id

  tags = {
    "AWSNetworkFirewallManaged" = "true"
    "Firewall"                  = aws_networkfirewall_firewall.main.arn
    "Name"                      = "${local.application_name}-${local.environment} (${data.aws_region.current.region}${each.key})"
  }
}
