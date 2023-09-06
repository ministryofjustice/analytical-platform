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
    cidr_block = var.noms_live_dead_end_cidr_block
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
    cidr_block         = var.modernisation_platform_cidr_block
    transit_gateway_id = var.transit_gateway_ids["airflow-dev-moj"]
  }
  route { # known dead end to noms-live
    cidr_block         = var.noms_live_dead_end_cidr_block
    transit_gateway_id = var.transit_gateway_ids["airflow-dev-moj"]
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

resource "aws_ec2_transit_gateway_vpc_attachment" "airflow_dev_cloud_platform" {
  subnet_ids         = aws_subnet.private_subnet[*].id
  transit_gateway_id = var.transit_gateway_ids["airflow-dev-cloud-platform"]
  vpc_id             = aws_vpc.airflow_dev.id
  tags = {
    Name = "airflow-dev-cloud-platform"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "airflow_dev_moj" {
  subnet_ids         = aws_subnet.private_subnet[*].id
  transit_gateway_id = var.transit_gateway_ids["airflow-dev-moj"]
  vpc_id             = aws_vpc.airflow_dev.id

  tags = {
    Name = "airflow-dev-moj"
  }
}

resource "aws_cloudwatch_log_group" "airflow_dev_vpc_flow_log" {
  name              = "airflow-dev-vpc-flow-log"
  retention_in_days = 400
  skip_destroy      = true
}

resource "aws_flow_log" "airflow_dev" {
  iam_role_arn    = aws_iam_role.airflow_dev_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.airflow_dev_vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.airflow_dev.id

  tags = {
    Name = "airflow-dev"
  }
}

resource "aws_security_group" "airflow_dev_security_group" {
  name        = var.dev_cluster_sg_name
  description = "Managed by Pulumi"
  vpc_id      = aws_vpc.airflow_dev.id
  ingress {
    description     = "Allow pods to communicate with the cluster API Server"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [var.dev_node_sg_id]
  }
  egress {
    description = "Allow internet access."
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
}

#      _     _         __  _                   ____                   _               _    _               
#     / \   (_) _ __  / _|| |  ___ __      __ |  _ \  _ __  ___    __| | _   _   ___ | |_ (_)  ___   _ __  
#    / _ \  | || '__|| |_ | | / _ \\ \ /\ / / | |_) || '__|/ _ \  / _` || | | | / __|| __|| | / _ \ | '_ \ 
#   / ___ \ | || |   |  _|| || (_) |\ V  V /  |  __/ | |  | (_) || (_| || |_| || (__ | |_ | || (_) || | | |
#  /_/   \_\|_||_|   |_|  |_| \___/  \_/\_/   |_|    |_|   \___/  \__,_| \__,_| \___| \__||_| \___/ |_| |_|
                                                                                                                                                                                             
resource "aws_vpc" "airflow_prod" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "airflow-prod"
  }
}

resource "aws_vpn_gateway" "airflow_prod" {
  vpc_id = aws_vpc.airflow_prod.id

  tags = {
    Name = "airflow-prod"
  }
}

resource "aws_internet_gateway" "airflow_prod" {
  vpc_id = aws_vpc.airflow_prod.id

  tags = {
    Name = "airflow-prod"
  }
}

resource "aws_eip" "airflow_prod_eip" {
  domain     = "vpc"
  count      = length(var.azs)
  depends_on = [aws_internet_gateway.airflow_prod]
  tags = {
    Name = "airflow-prod-${element(var.azs, count.index)}"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.airflow_prod.id
  count             = length(var.public_subnet_cidrs)
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "airflow-prod-public-${element(var.azs, count.index)}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.airflow_prod.id
  count             = length(var.private_subnet_cidrs)
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "airflow-prod-private-${element(var.azs, count.index)}"
  }
}

resource "aws_nat_gateway" "airflow_prod" {
  count         = length(var.azs)
  allocation_id = aws_eip.airflow_prod_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name = "airflow-prod-${element(var.azs, count.index)}"
  }

  depends_on = [aws_subnet.public_subnet]
}

resource "aws_route_table" "airflow_prod_public" {
  vpc_id = aws_vpc.airflow_prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.airflow_prod.id
  }
  route { # known dead end to noms-live
    cidr_block = var.noms_live_dead_end_cidr_block
    gateway_id = aws_internet_gateway.airflow_prod.id
  }

  tags = {
    Name = "airflow-prod-public"
  }
}

resource "aws_route_table_association" "airflow_prod_public_route_table_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.airflow_prod_public.id
}

resource "aws_route_table" "airflow_prod_private" {
  vpc_id = aws_vpc.airflow_prod.id
  count  = length(var.azs)

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.airflow_prod[count.index].id
  }
  route {
    cidr_block         = var.modernisation_platform_cidr_block
    transit_gateway_id = var.transit_gateway_ids["airflow-prod-moj"]
  }
  route { # known dead end to noms-live
    cidr_block         = var.noms_live_dead_end_cidr_block
    transit_gateway_id = var.transit_gateway_ids["airflow-prod-moj"]
  }

  tags = {
    Name = "airflow-prod-private-${element(var.azs, count.index)}"
  }
}

resource "aws_route_table_association" "airflow_prod_private_route_table_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.airflow_prod_private[count.index].id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "airflow_prod_cloud_platform" {
  subnet_ids         = aws_subnet.private_subnet[*].id
  transit_gateway_id = var.transit_gateway_ids["airflow-prod-cloud-platform"]
  vpc_id             = aws_vpc.airflow_prod.id
  tags = {
    Name = "airflow-prod-cloud-platform"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "airflow_prod_moj" {
  subnet_ids         = aws_subnet.private_subnet[*].id
  transit_gateway_id = var.transit_gateway_ids["airflow-prod-moj"]
  vpc_id             = aws_vpc.airflow_prod.id

  tags = {
    Name = "airflow-prod-moj"
  }
}

resource "aws_cloudwatch_log_group" "airflow_prod_vpc_flow_log" {
  name              = "airflow-prod-vpc-flow-log"
  retention_in_days = 400
  skip_destroy      = true
}

resource "aws_flow_log" "airflow_prod" {
  iam_role_arn    = aws_iam_role.airflow_prod_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.airflow_prod_vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.airflow_prod.id

  tags = {
    Name = "airflow-prod"
  }
}

resource "aws_security_group" "airflow_prod_security_group" {
  name        = var.prod_cluster_sg_name
  description = "Managed by Pulumi"
  vpc_id      = aws_vpc.airflow_prod.id
  ingress {
    description     = "Allow pods to communicate with the cluster API Server"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [var.prod_node_sg_id]
  }
  egress {
    description = "Allow internet access."
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
}