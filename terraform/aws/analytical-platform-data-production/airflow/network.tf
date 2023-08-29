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
