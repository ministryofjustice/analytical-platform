data "aws_ami" "windows_server_2022" {
  most_recent = local.powerbi_gateway_ec2.most_recent
  owners      = [local.powerbi_gateway_ec2.owner_account]

  filter {
    name   = "name"
    values = local.powerbi_gateway_ec2.name
  }
  filter {
    name   = "virtualization-type"
    values = [local.powerbi_gateway_ec2.virtualization_type]
  }
}

data "aws_iam_policy" "powerbi_user" {
  name = "powerbi_user"
}

resource "aws_key_pair" "powerbi_gateway_keypair" {
  key_name   = "powerbi-gateway-keypair"
  public_key = local.powerbi_gateway_ec2.ssh_pub_key
}

module "ec2" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "6.0.2"
  name                        = local.powerbi_gateway_ec2.instance_name
  ami                         = data.aws_ami.windows_server_2022.id
  instance_type               = local.powerbi_gateway_ec2.instance_type
  key_name                    = aws_key_pair.powerbi_gateway_keypair.key_name
  monitoring                  = true
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for PowerBI Gateway Instance"
  ignore_ami_changes          = true
  enable_volume_tags          = false
  associate_public_ip_address = false
  iam_role_name               = local.powerbi_gateway_role

  iam_role_policies = {
    SSMCore            = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    PowerBI_DataAccess = data.aws_iam_policy.powerbi_user.arn
    ReadOnlyAccess     = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }
  root_block_device = {
    encrypted = true
    type      = "gp3"
    size      = 100
    tags = merge({
      Name = "${local.powerbi_gateway_ec2.instance_name}-root-volume"
    }, var.tags)
  }

  ebs_volumes = {
    "/dev/sdf" = {
      encrypted = true
      type      = "gp3"
      size      = 300
      tags = merge({
        Name = "${local.powerbi_gateway_ec2.instance_name}-data-volume"
      }, var.tags)
    }
  }
  metadata_options = {
    http_tokens = "required"
  }

  create_security_group  = false
  vpc_security_group_ids = [module.security_group.security_group_id]
  subnet_id              = module.vpc.private_subnets[0]

  tags = var.tags
}

# Required for terraform-aws-modules/ec2-instance v6 update
# https://github.com/terraform-aws-modules/terraform-aws-ec2-instance/blob/master/docs/UPGRADE-6.0.md
import {
  to = module.ec2.aws_ebs_volume.this["/dev/sdf"]
  id = "vol-0e5e107a9fa170d75"
}

import {
  to = module.ec2.aws_volume_attachment.this["/dev/sdf"]
  id = "/dev/sdf:vol-0e5e107a9fa170d75:i-0e4ebbfb11d8afeaf"
}
