module "hmcts_sdp_nlb" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name               = "hmcts-sdp"
  load_balancer_type = "network"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.private_subnets
  internal           = true

  security_group_ingress_rules = {
    all_tcp = {
      from_port   = 443
      to_port     = 445
      ip_protocol = "tcp"
      description = "TCP traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  target_groups = {
    miexportstg = {
      name              = "miexportstg"
      target_type       = "ip"
      target_id         = "10.168.3.7"
      port              = 443
      protocol          = "TCP"
      availability_zone = "all"
      health_check = {
        enabled  = true
        port     = "443"
        protocol = "TCP"
      }
    }
    miexportithc = {
      name              = "miexportithc"
      target_type       = "ip"
      target_id         = "10.168.4.5"
      port              = 443
      protocol          = "TCP"
      availability_zone = "all"
      health_check = {
        enabled  = true
        port     = "443"
        protocol = "TCP"
      }
    }
    mipersistentithc = {
      name              = "mipersistentithc"
      target_type       = "ip"
      target_id         = "10.168.4.13"
      port              = 443
      protocol          = "TCP"
      availability_zone = "all"
      health_check = {
        enabled  = true
        port     = "443"
        protocol = "TCP"
      }
    }
  }

  listeners = {
    miexportstg = {
      port     = 443
      protocol = "TCP"
      forward = {
        target_group_key = "miexportstg"
      }
    }
    miexportithc = {
      port     = 444
      protocol = "TCP"
      forward = {
        target_group_key = "miexportithc"
      }
    }
    mipersistentithc = {
      port     = 445
      protocol = "TCP"
      forward = {
        target_group_key = "mipersistentithc"
      }
    }
  }
}
