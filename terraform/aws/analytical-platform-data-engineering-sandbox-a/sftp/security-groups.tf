resource "aws_security_group" "transfer_server" {
  name   = "transfer-server"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "jacobwoffenden" {
  type              = "ingress"
  from_port         = 2222
  to_port           = 2222
  protocol          = "tcp"
  cidr_blocks       = ["90.246.52.170/32"]
  security_group_id = aws_security_group.transfer_server.id
}
