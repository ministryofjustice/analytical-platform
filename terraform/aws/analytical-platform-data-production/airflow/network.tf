resource "aws_vpc" "airflow_dev" {
    cidr_block = "10.200.0.0/16"

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