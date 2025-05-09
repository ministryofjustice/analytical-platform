resource "aws_iam_role" "dev_bastion_ec2" {
  name = "dev-bastion-ec2"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags

}

# IAM Role Policy for EC2 to allow ssm session manager
resource "aws_iam_role_policy_attachment" "dev_bastion_ec2_ssm" {
  role       = aws_iam_role.dev_bastion_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "dev_bastion_ec2" {
  name = "dev-bastion-ec2-instance-profile"
  role = aws_iam_role.dev_bastion_ec2.name
}


data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "dev_bastion_ec2" {
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

}

resource "aws_instance" "dev_bastion_ec2" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3a.nano"
  iam_instance_profile   = aws_iam_instance_profile.dev_bastion_ec2.name
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.dev_bastion_ec2.id]

  tags = merge(
    {
      Name = "dev-bastion-ec2"
    },
    var.tags
  )
}
