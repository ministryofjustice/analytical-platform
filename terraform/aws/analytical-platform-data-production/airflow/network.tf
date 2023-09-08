resource "aws_vpc" "airflow_dev" {
  cidr_block = var.dev_vpc_cidr_block

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
  count             = length(var.dev_public_subnet_cidrs)
  cidr_block        = element(var.dev_public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "airflow-dev-public-${element(var.azs, count.index)}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.airflow_dev.id
  count             = length(var.dev_private_subnet_cidrs)
  cidr_block        = element(var.dev_private_subnet_cidrs, count.index)
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
    transit_gateway_id = var.transit_gateway_ids["airflow-moj"]
  }
  route { # known dead end to noms-live
    cidr_block         = var.noms_live_dead_end_cidr_block
    transit_gateway_id = var.transit_gateway_ids["airflow-moj"]
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
  transit_gateway_id = var.transit_gateway_ids["airflow-cloud-platform"]
  vpc_id             = aws_vpc.airflow_dev.id
  tags = {
    Name = "airflow-cloud-platform"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "airflow_dev_moj" {
  subnet_ids         = aws_subnet.private_subnet[*].id
  transit_gateway_id = var.transit_gateway_ids["airflow-moj"]
  vpc_id             = aws_vpc.airflow_dev.id

  tags = {
    Name = "airflow-moj"
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
  cidr_block = var.prod_vpc_cidr_block

  tags = {
    Name = "airflow-prod"
  }
}

import {
  to = aws_vpc.airflow_prod
  id = "vpc-047b97f77da3ab143"
}

resource "aws_vpn_gateway" "airflow_prod" {
  vpc_id = aws_vpc.airflow_prod.id

  tags = {
    Name = "airflow-prod"
  }
}

import {
  to = aws_vpn_gateway.airflow_prod
  id = "vgw-099d9b2d0d3576880"
}

resource "aws_internet_gateway" "airflow_prod" {
  vpc_id = aws_vpc.airflow_prod.id

  tags = {
    Name = "airflow-prod"
  }
}

import {
  to = aws_internet_gateway.airflow_prod
  id = "igw-02079c6025e743da9"
}

resource "aws_eip" "airflow_prod_eip" {
  domain     = "vpc"
  count      = length(var.azs)
  depends_on = [aws_internet_gateway.airflow_prod]
  tags = {
    Name = "airflow-prod-${element(var.azs, count.index)}"
  }
}

import {
  to = aws_eip.airflow_prod_eip[0]
  id = "eipalloc-004b4c772fe008f20"
}

import {
  to = aws_eip.airflow_prod_eip[1]
  id = "eipalloc-0662dcc8c3021166d"
}

import {
  to = aws_eip.airflow_prod_eip[2]
  id = "eipalloc-06014aa6601f513cc"
}

resource "aws_subnet" "public_subnet_prod" {
  vpc_id                  = aws_vpc.airflow_prod.id
  count                   = length(var.prod_public_subnet_cidrs)
  cidr_block              = element(var.prod_public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "airflow-prod-public-${element(var.azs, count.index)}"
  }
}

import {
  to = aws_subnet.public_subnet_prod[0]
  id = "subnet-0f54bacad347f9655"
}

import {
  to = aws_subnet.public_subnet_prod[1]
  id = "subnet-05bb7417f09a6e793"
}

import {
  to = aws_subnet.public_subnet_prod[2]
  id = "subnet-06a2a1bedf4b15c59"
}

resource "aws_subnet" "private_subnet_prod" {
  vpc_id            = aws_vpc.airflow_prod.id
  count             = length(var.prod_private_subnet_cidrs)
  cidr_block        = element(var.prod_private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "airflow-prod-private-${element(var.azs, count.index)}"
  }
}

import {
  to = aws_subnet.private_subnet_prod[0]
  id = "subnet-03ffba4faab8b77e7"
}

import {
  to = aws_subnet.private_subnet_prod[1]
  id = "subnet-076487802dbb8abd5"
}

import {
  to = aws_subnet.private_subnet_prod[2]
  id = "subnet-026210746906f54d3"
}

resource "aws_nat_gateway" "airflow_prod" {
  count         = length(var.azs)
  allocation_id = aws_eip.airflow_prod_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet_prod[count.index].id

  tags = {
    Name = "airflow-prod-${element(var.azs, count.index)}"
  }

  depends_on = [aws_subnet.public_subnet_prod]
}

import {
  to = aws_nat_gateway.airflow_prod[0]
  id = "nat-025030526a14d65af"
}

import {
  to = aws_nat_gateway.airflow_prod[1]
  id = "nat-01ed37c242b6adb5a"
}

import {
  to = aws_nat_gateway.airflow_prod[2]
  id = "nat-08926bf064929356a"
}

resource "aws_route_table" "airflow_prod_public" {
  vpc_id = aws_vpc.airflow_prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.airflow_prod.id
  }

  tags = {
    Name = "airflow-prod-public"
  }
}

import {
  to = aws_route_table.airflow_prod_public
  id = "rtb-004834ed1981fdd94"
}

resource "aws_route_table_association" "airflow_prod_public_route_table_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public_subnet_prod[count.index].id
  route_table_id = aws_route_table.airflow_prod_public.id
}

import {
  to = aws_route_table_association.airflow_prod_public_route_table_assoc[0]
  id = "subnet-0f54bacad347f9655/rtb-004834ed1981fdd94"
}

import {
  to = aws_route_table_association.airflow_prod_public_route_table_assoc[1]
  id = "subnet-05bb7417f09a6e793/rtb-004834ed1981fdd94"
}

import {
  to = aws_route_table_association.airflow_prod_public_route_table_assoc[2]
  id = "subnet-06a2a1bedf4b15c59/rtb-004834ed1981fdd94"
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
    transit_gateway_id = var.transit_gateway_ids["airflow-moj"]
  }
  route {
    cidr_block         = var.laa_prod_cidr_block
    transit_gateway_id = var.transit_gateway_ids["airflow-moj"]
  }
  route { # known dead end to noms-live
    cidr_block         = var.noms_live_dead_end_cidr_block
    transit_gateway_id = var.transit_gateway_ids["airflow-moj"]
  }

  tags = {
    Name = "airflow-prod-private-${element(var.azs, count.index)}"
  }
}

import {
  to = aws_route_table.airflow_prod_private[0]
  id = "rtb-0ad1ea83e40664bc1"
}

import {
  to = aws_route_table.airflow_prod_private[1]
  id = "rtb-045cda0b792473e86"
}

import {
  to = aws_route_table.airflow_prod_private[2]
  id = "rtb-06500bda1e9933d28"
}

resource "aws_route_table_association" "airflow_prod_private_route_table_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_subnet_prod[count.index].id
  route_table_id = aws_route_table.airflow_prod_private[count.index].id
}

import {
  to = aws_route_table_association.airflow_prod_private_route_table_assoc[0]
  id = "subnet-03ffba4faab8b77e7/rtb-0ad1ea83e40664bc1"
}

import {
  to = aws_route_table_association.airflow_prod_private_route_table_assoc[1]
  id = "subnet-076487802dbb8abd5/rtb-045cda0b792473e86"
}

import {
  to = aws_route_table_association.airflow_prod_private_route_table_assoc[2]
  id = "subnet-026210746906f54d3/rtb-06500bda1e9933d28"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "airflow_prod_cloud_platform" {
  subnet_ids         = aws_subnet.private_subnet_prod[*].id
  transit_gateway_id = var.transit_gateway_ids["airflow-cloud-platform"]
  vpc_id             = aws_vpc.airflow_prod.id
  tags = {
    Name = "airflow-cloud-platform"
  }
}

import {
  to = aws_ec2_transit_gateway_vpc_attachment.airflow_prod_cloud_platform
  id = "tgw-attach-0b2c29f4fcb9de1a4"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "airflow_prod_moj" {
  subnet_ids         = aws_subnet.private_subnet_prod[*].id
  transit_gateway_id = var.transit_gateway_ids["airflow-moj"]
  vpc_id             = aws_vpc.airflow_prod.id

  tags = {
    Name = "airflow-moj"
  }
}

import {
  to = aws_ec2_transit_gateway_vpc_attachment.airflow_prod_moj
  id = "tgw-attach-0a95490e9dca306be"
}

resource "aws_cloudwatch_log_group" "airflow_prod_vpc_flow_log" {
  name              = "airflow-prod-vpc-flow-log"
  retention_in_days = 400
  skip_destroy      = true
}

import {
  to = aws_cloudwatch_log_group.airflow_prod_vpc_flow_log
  id = "airflow-prod-vpc-flow-log"
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

import {
  to = aws_flow_log.airflow_prod
  id = "fl-06f1a246ed4ecb51d"
}

resource "aws_security_group" "airflow_prod_security_group" {
  name        = var.prod_vpc_sg_name
  description = "Managed by Pulumi"
  vpc_id      = aws_vpc.airflow_prod.id
  ingress {
    description     = ""
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    security_groups = []
    self            = true
  }
  egress {
    description = ""
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
}

import {
  to = aws_security_group.airflow_prod_security_group
  id = "sg-0d278497bb1ee3617"
}
