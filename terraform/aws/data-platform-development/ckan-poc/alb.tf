##################################################
# CKAN ALB
##################################################

module "ckan_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.6.0"

  name = "data-platform-development-ckan"

  vpc_id          = data.aws_vpc.mp_platforms_development.id
  subnets         = data.aws_subnets.mp_platforms_development_general_public.ids
  security_groups = [module.ckan_alb_security_group.security_group_id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name_prefix                       = "tg"
      backend_protocol                  = "HTTP"
      backend_port                      = 5000
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      protocol_version                  = "HTTP1"
      targets = {
        ckan_ec2 = {
          target_id = module.ckan_ec2_instance.id
          port      = 5000
        }
      }
    }
  ]
}
