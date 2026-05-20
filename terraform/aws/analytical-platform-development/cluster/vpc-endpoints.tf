##################################################
# Amazon Managed Prometheus
##################################################

resource "aws_vpc_endpoint" "aps" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.eu-west-1.aps-workspaces"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.aps.id]
}
