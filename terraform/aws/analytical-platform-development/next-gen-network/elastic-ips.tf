resource "aws_eip" "nat_gateway" {
  for_each = local.environment_configuration.vpc_subnets.public

  domain = "vpc"

  tags = {
    Name = "${local.application_name}-${local.environment}-nat-gateway-${each.key}"
  }
}
