/* VPC already exists in APC, this is a dummy */
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  name            = local.project_name
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr            = "10.200.0.0/18"
  public_subnets  = ["10.200.0.0/27", "10.200.0.32/27", "10.200.0.64/27"]
  private_subnets = ["10.200.32.0/21", "10.200.40.0/21", "10.200.48.0/21"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = false
  single_nat_gateway     = true

  enable_flow_log = false
}
