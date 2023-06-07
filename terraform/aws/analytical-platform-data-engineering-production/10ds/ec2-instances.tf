module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.1.0"

  name                        = local.name
  ami                         = local.ami
  instance_type               = local.instance_type
  availability_zone           = local.azs[0]
  subnet_id                   = element(module.vpc.private_subnets, 0)
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = false

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 8
    }
  ]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = 10
      encrypted   = true
    }
  ]

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    SSMCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Name = local.name
  }
}
