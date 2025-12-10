resource "aws_route_table" "main" {
  for_each = local.all_subnets

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.application_name}-${local.environment}-${each.value.type}-${each.value.az}"
  }
}

resource "aws_route_table_association" "main" {
  for_each = local.all_subnets

  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.main[each.key].id
}

resource "aws_route_table" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.application_name}-${local.environment}-igw"
  }
}

resource "aws_route_table_association" "internet_gateway" {
  gateway_id     = aws_internet_gateway.main.id
  route_table_id = aws_route_table.internet_gateway.id
}
