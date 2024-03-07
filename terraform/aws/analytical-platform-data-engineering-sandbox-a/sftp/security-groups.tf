resource "aws_security_group" "transfer_server" {
  name   = "transfer-server"
  vpc_id = module.vpc.vpc_id
}
