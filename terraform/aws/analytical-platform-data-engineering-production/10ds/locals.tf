locals {
  name = "data-engineering-app-vpc"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 1)

  ami           = "ami-0256f8c0fabe51702" # can't pass ignore_changes to module, so must statically code
  instance_type = "t3.medium"
}
