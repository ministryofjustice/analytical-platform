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
  count      = length(var.azs)
  subnet_id = aws_subnet.public_subnet[count.index].id # er, refer to each of aws_subnet.public_subnet[0].id etc 
  route_table_id = aws_route_table.airflow_dev_public.id
}




# local routes are added by default
# 


    # ├─ aws:ec2/vpc:Vpc                                               airflow-dev
    # │  │  ID: vpc-0a6cb83c3c614dcba
    # │  ├─ aws:ec2/vpnGateway:VpnGateway                              airflow-dev
    # │  │     ID: vgw-02f10f1bacf2dd3fa

    # │  ├─ aws:ec2/routeTable:RouteTable                              airflow-dev-public
    # │  │  │  ID: rtb-0595299e5f01affbc
    # │  │  ├─ aws:ec2/route:Route                                     airflow-dev-public
    # │  │  │     ID: r-rtb-0595299e5f01affbc1080289494
    # │  │  ├─ aws:ec2/routeTableAssociation:RouteTableAssociation     airflow-dev-public-eu-west-1a
    # │  │  │     ID: rtbassoc-09ff6362679886379
    # │  │  ├─ aws:ec2/routeTableAssociation:RouteTableAssociation     airflow-dev-public-eu-west-1b
    # │  │  │     ID: rtbassoc-0fe50d22a9f4e62d6
    # │  │  └─ aws:ec2/routeTableAssociation:RouteTableAssociation     airflow-dev-public-eu-west-1c
    # │  │        ID: rtbassoc-0ddc9ee4346646e72

    # │  ├─ aws:ec2/subnet:Subnet                                      airflow-dev-public-eu-west-1b
    # │  │  │  ID: subnet-0d63aad6294936483
    # │  │  └─ aws:ec2/natGateway:NatGateway                           airflow-dev-eu-west-1b
    # │  │        ID: nat-073cf7877cabf937e
    # │  ├─ aws:ec2/subnet:Subnet                                      airflow-dev-private-eu-west-1a
    # │  │  │  ID: subnet-02c12ac78aa071d71
    # │  │  └─ aws:ec2/routeTable:RouteTable                           airflow-dev-private-eu-west-1a
    # │  │     │  ID: rtb-0253f5d2ff173c5fb
    # │  │     ├─ aws:ec2/routeTableAssociation:RouteTableAssociation  airflow-dev-private-eu-west-1a
    # │  │     │     ID: rtbassoc-0ef022e00cd23cafe
    # │  │     ├─ aws:ec2/route:Route                                  airflow-dev-private-eu-west-1a-moj-noms-live
    # │  │     │     ID: r-rtb-0253f5d2ff173c5fb3017512065
    # │  │     ├─ aws:ec2/route:Route                                  airflow-dev-private-eu-west-1a-moj-modernisation-platform
    # │  │     │     ID: r-rtb-0253f5d2ff173c5fb2015336497
    # │  │     └─ aws:ec2/route:Route                                  airflow-dev-private-eu-west-1a
    # │  │           ID: r-rtb-0253f5d2ff173c5fb1080289494
    # │  ├─ aws:ec2/subnet:Subnet                                      airflow-dev-public-eu-west-1c
    # │  │  │  ID: subnet-02a13fd4fd56ee6c5
    # │  │  └─ aws:ec2/natGateway:NatGateway                           airflow-dev-eu-west-1c
    # │  │        ID: nat-084c200fc4a3d033d
    # │  ├─ aws:ec2/subnet:Subnet                                      airflow-dev-private-eu-west-1b
    # │  │  │  ID: subnet-0984267608686a5ce
    # │  │  └─ aws:ec2/routeTable:RouteTable                           airflow-dev-private-eu-west-1b
    # │  │     │  ID: rtb-0c26df12e1ebf0f26
    # │  │     ├─ aws:ec2/routeTableAssociation:RouteTableAssociation  airflow-dev-private-eu-west-1b
    # │  │     │     ID: rtbassoc-01dfd6f923442daa3
    # │  │     ├─ aws:ec2/route:Route                                  airflow-dev-private-eu-west-1b-moj-noms-live
    # │  │     │     ID: r-rtb-0c26df12e1ebf0f263017512065
    # │  │     ├─ aws:ec2/route:Route                                  airflow-dev-private-eu-west-1b-moj-modernisation-platform
    # │  │     │     ID: r-rtb-0c26df12e1ebf0f262015336497
    # │  │     └─ aws:ec2/route:Route                                  airflow-dev-private-eu-west-1b
    # │  │           ID: r-rtb-0c26df12e1ebf0f261080289494
    # │  ├─ aws:ec2/subnet:Subnet                                      airflow-dev-private-eu-west-1c
    # │  │  │  ID: subnet-0f0f0e17d45e9791f
    # │  │  └─ aws:ec2/routeTable:RouteTable                           airflow-dev-private-eu-west-1c
    # │  │     │  ID: rtb-01ea0e0adfe7b734c
    # │  │     ├─ aws:ec2/routeTableAssociation:RouteTableAssociation  airflow-dev-private-eu-west-1c
    # │  │     │     ID: rtbassoc-05a22f993ab6f9f96
    # │  │     ├─ aws:ec2/route:Route                                  airflow-dev-private-eu-west-1c-moj-noms-live
    # │  │     │     ID: r-rtb-01ea0e0adfe7b734c3017512065
    # │  │     ├─ aws:ec2/route:Route                                  airflow-dev-private-eu-west-1c-moj-modernisation-platform
    # │  │     │     ID: r-rtb-01ea0e0adfe7b734c2015336497
    # │  │     └─ aws:ec2/route:Route                                  airflow-dev-private-eu-west-1c
    # │  │           ID: r-rtb-01ea0e0adfe7b734c1080289494

