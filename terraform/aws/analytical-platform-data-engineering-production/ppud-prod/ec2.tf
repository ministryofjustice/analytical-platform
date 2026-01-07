# resource "aws_iam_role" "ec2_role" {
#   name = "${local.name}-${local.env}-ec2"
#   assume_role_policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "ec2.amazonaws.com"
#         },
#         "Action" : "sts:AssumeRole"
#       }
#     ]
#   })

#   tags = var.tags

# }

# # IAM Role Policy for EC2 to allow ssm session manager
# resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# # Instance Profile for EC2
# resource "aws_iam_instance_profile" "ec2_profile" {
#   name = "${local.name}-${local.env}-ec2-instance-profile"
#   role = aws_iam_role.ec2_role.name
# }

# data "aws_ssm_parameter" "al2023" {
#   name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
# }

# # trivy:ignore:avd-aws-0104: Required for SSM
# resource "aws_security_group" "ec2_sg" {
#   # checkov:skip=CKV_AWS_382: Required for SSM
#   name        = "allow_access"
#   description = "allow inbound traffic"
#   vpc_id      = module.vpc.vpc_id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Enable access to the internet"
#   }

#   tags = var.tags
# }

# resource "aws_instance" "ec2" {
#   # checkov:skip=CKV_AWS_126: Skipping because detailed monitoring not needed for the EC2 instance to test connectivity to the source databases, basic monitoring is enough and is free.
#   # checkov:skip=CKV_AWS_135: Skipping becuase t3a.nano is EBS optimized by default.
#   ami                    = data.aws_ssm_parameter.al2023.value
#   instance_type          = "t3a.nano"
#   iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
#   subnet_id              = module.vpc.private_subnets[0]
#   vpc_security_group_ids = [aws_security_group.ec2_sg.id]
#   root_block_device {
#     encrypted = true #fixes CKV_AWS_8
#   }
#   metadata_options {
#     http_tokens = "required"
#   }

#   tags = merge(
#     {
#       Name = "${local.name}-${local.env}-ec2"
#     },
#     var.tags
#   )
# }
