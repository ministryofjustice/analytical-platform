resource "aws_vpc" "airflow_dev" {
    cidr_block = "10.200.0.0/16"

    tags = {
      Name = "airflow-dev"
    }
}
