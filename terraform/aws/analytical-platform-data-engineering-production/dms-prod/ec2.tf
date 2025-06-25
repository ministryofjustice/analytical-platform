resource "aws_iam_role" "prod_bastion_ec2" {
  name = "prod-bastion-ec2"
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
resource "aws_iam_role_policy_attachment" "prod_bastion_ec2_ssm" {
  role       = aws_iam_role.prod_bastion_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "prod_bastion_ec2" {
  name = "prod-bastion-ec2-instance-profile"
  role = aws_iam_role.prod_bastion_ec2.name
}


data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

#trivy:ignore:AVD-AWS-0099:Using default description.
#trivy:ignore:AVD-AWS-0124:Using default description.
#trivy:ignore:AVD-AWS-0104:Just a prod bastion to test source connection to database.
resource "aws_security_group" "prod_bastion_ec2" {
  # checkov:skip=CKV_AWS_23: Skipping as Terraform adds a default description.
  # checkov:skip=CKV_AWS_382: Skipping as prod bastion.
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

}

resource "aws_instance" "prod_bastion_ec2" {
  # checkov:skip=CKV_AWS_126: Skipping because detailed monitoring not needed for the EC2 instance to test connectivity to the source databases, basic monitoring is enough and is free.
  # checkov:skip=CKV_AWS_135: Skipping becuase t3a.nano is EBS optimized by default.
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3a.nano"
  iam_instance_profile   = aws_iam_instance_profile.prod_bastion_ec2.name
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.prod_bastion_ec2.id]
  root_block_device {
    encrypted = true #fixes CKV_AWS_8
  }
  metadata_options {
    http_tokens = "required"
  }

  tags = merge(
    {
      Name = "prod-bastion-ec2"
    },
    var.tags
  )
}
