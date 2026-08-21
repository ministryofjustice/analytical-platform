resource "aws_security_group" "ec2_security_group" {
  name        = "ec2_security_group"
  description = "Security group for EC2 instance"
  tags        = var.tags
  egress {
    to_port     = 80
    from_port   = 80
    description = "Allow HTTP outbound traffic"
    cidr_blocks = ["10.0.0.0/16"]
    protocol    = "tcp"
  }
}
