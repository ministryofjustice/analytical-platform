data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_route53_zone" "dev_analytical_platform_service_justice_gov_uk" {
  name = "dev.analytical-platform.service.justice.gov.uk"
}

data "aws_vpc_endpoint" "mwaa_webserver" {
  service_name = aws_mwaa_environment.main.webserver_vpc_endpoint_service
}

data "dns_a_record_set" "mwaa_webserver_vpc_endpoint" {
  host = data.aws_vpc_endpoint.mwaa_webserver.dns_entry[0].dns_name
}

# data "aws_network_interface" "mwaa_webserver_vpce_network_interface_ids" {
#   for_each = data.aws_vpc_endpoint.mwaa_webserver.network_interface_ids
#   id       = each.value
# }

# output "mwaa_webserver_vpce_dns_entry" {
#   value = data.aws_vpc_endpoint.mwaa_webserver.dns_entry
# }

# output "mwaa_webserver_vpce_network_interface_ids" {
#   value = data.aws_vpc_endpoint.mwaa_webserver.network_interface_ids
# }

# output "mwaa_webserver_vpce_network_interface_private_ips" {
#   value = [for i in data.aws_network_interface.mwaa_webserver_vpce_network_interface_ids : i.private_ip]
# }
