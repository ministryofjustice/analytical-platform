resource "aws_vpc" "airflow_dev" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "airflow-dev"
  }
}

resource "aws_vpn_gateway" "airflow_dev" {
  vpc_id = aws_vpc.airflow_dev.id

  tags = {
    Name = "airflow-dev"
  }
}

resource "aws_internet_gateway" "airflow_dev" {
  vpc_id = aws_vpc.airflow_dev.id

  tags = {
    Name = "airflow-dev"
  }
}

resource "aws_eip" "airflow_dev_eip" {
  domain     = "vpc"
  count      = length(var.azs)
  depends_on = [aws_internet_gateway.airflow_dev]
  tags = {
    Name = "airflow-dev-${element(var.azs, count.index)}"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.airflow_dev.id
  count             = length(var.public_subnet_cidrs)
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "airflow-dev-public-${element(var.azs, count.index)}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.airflow_dev.id
  count             = length(var.private_subnet_cidrs)
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "airflow-dev-private-${element(var.azs, count.index)}"
  }
}

resource "aws_nat_gateway" "airflow_dev" {
  count         = length(var.azs)
  allocation_id = aws_eip.airflow_dev_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name = "airflow-dev-${element(var.azs, count.index)}"
  }

  depends_on = [aws_subnet.public_subnet]
}

resource "aws_route_table" "airflow_dev_public" {
  vpc_id = aws_vpc.airflow_dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.airflow_dev.id
  }
  route { # known dead end to noms-live
    cidr_block = "10.40.0.0/18"
    gateway_id = aws_internet_gateway.airflow_dev.id
  }

  tags = {
    Name = "airflow-dev-public"
  }
}

resource "aws_route_table_association" "airflow_dev_public_route_table_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.airflow_dev_public.id
}

resource "aws_route_table" "airflow_dev_private" {
  vpc_id = aws_vpc.airflow_dev.id
  count  = length(var.azs)

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.airflow_dev[count.index].id
  }
  route {
    cidr_block         = "10.26.0.0/15"
    transit_gateway_id = "tgw-0e7b982ea47c28fba"
  }
  route { # known dead end to noms-live
    cidr_block         = "10.40.0.0/18"
    transit_gateway_id = "tgw-0e7b982ea47c28fba"
  }

  tags = {
    Name = "airflow-dev-private-${element(var.azs, count.index)}"
  }
}

resource "aws_route_table_association" "airflow_dev_private_route_table_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.airflow_dev_private[count.index].id
}

resource "aws_cloudwatch_log_group" "airflow_dev_vpc_flow_log_group" {
  name = "airflow-dev-vpc-flow-log-group"
}

resource "aws_flow_log" "airflow_dev" {
  iam_role_arn    = aws_iam_role.airflow_dev_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.airflow_dev_vpc_flow_log_group.arn
  traffic_type    = "ALL" # ???
  vpc_id          = aws_vpc.airflow_dev.id
}
# flow log components
# │  ├─ aws:ec2/flowLog:FlowLog                                    airflow-dev
# │  │     ID: fl-0f0649a3bb58c8feb

# ├─ aws:cloudwatch/logGroup:LogGroup                              airflow-dev-vpc-flow-log
# │     ID: airflow-dev-vpc-flow-log

# ├─ aws:iam/role:Role                                             airflow-dev-flow-log-role
# │     ID: airflow-dev-flow-log-role
