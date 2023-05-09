##################################################
# CKAN EC2
##################################################

module "ckan_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.0.0"

  name = "data-platform-development-ckan"

  ami_ssm_parameter = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type     = "t3.large"
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 150
    }
  ]
  user_data_base64            = base64encode(file("${path.module}/src/user-data.sh"))
  user_data_replace_on_change = true

  subnet_id              = data.aws_subnets.mp_platforms_development_general_private.ids[0]
  vpc_security_group_ids = [module.ckan_ec2_security_group.security_group_id]

  create_iam_instance_profile = true
  iam_role_name               = "data-platform-development-ckan"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}
