module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.12.0"

  name    = local.project_name
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }
  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.certificate.acm_certificate_arn

      forward = {
        target_group_key = "ex-mwaa"
      }
    }
  }
  target_groups = {
    ex-mwaa = {
      name_prefix = "tg"
      protocol    = "HTTPS"
      port        = 443
      target_type = "ip"
      target_id   = data.dns_a_record_set.mwaa_webserver_vpc_endpoint.addrs[0]
      health_check = {
        enabled  = true
        path     = "/"
        port     = "traffic-port"
        protocol = "HTTPS"
        matcher  = "200,302"
      }
    }
  }
  additional_target_group_attachments = {
    ex-mwaa = {
      target_group_key = "ex-mwaa"
      target_id        = data.dns_a_record_set.mwaa_webserver_vpc_endpoint.addrs[1]
      port             = 443
    }
  }
  # route53_records = {
  #   zephyr = {
  #     name    = "zephyr"
  #     type    = "CNAME"
  #     zone_id = data.aws_route53_zone.dev_analytical_platform_service_justice_gov_uk.zone_id
  #   }
  # }
}
