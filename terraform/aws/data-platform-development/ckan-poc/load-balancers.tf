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

  listener_ssl_policy_default = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      action_type        = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      target_group_index = 0
      certificate_arn    = aws_acm_certificate.ckan.arn
    }
  ]

  target_groups = [
    {
      name_prefix                       = "tg"
      backend_protocol                  = "HTTPS"
      backend_port                      = 8443
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      protocol_version                  = "HTTP1"
      targets = {
        ckan_ec2 = {
          target_id = module.ckan_ec2_instance.id
          port      = 8443
        }
      }
    }
  ]
}
