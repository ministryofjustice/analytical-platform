# resource "aws_dx_private_virtual_interface" "hmcts_cloudgateway_connection" {
#   name             = "HMCTS_CloudGateway_Connection"
#   connection_id    = aws_dx_connection.hmcts_mojap.id
#   address_family   = "ipv4"
#   bgp_asn          = 205098
#   bgp_auth_key     = data.aws_secretsmanager_secret_version.hmcts_cloudgateway_bgp_auth_key.secret_string
#   customer_address = "169.254.88.1/30"
#   dx_gateway_id    = aws_dx_gateway.hmcts_gateway.id
#   sitelink_enabled = false
#   vlan             = "309"
# }

# resource "aws_dx_private_virtual_interface" "hmcts_cloudgateway_connection_secondary" {
#   name             = "HMCTS_CloudGateway_Connection_Secondary"
#   connection_id    = aws_dx_connection.hmcts_mojap_sec.id
#   address_family   = "ipv4"
#   bgp_asn          = 205098
#   bgp_auth_key     = data.aws_secretsmanager_secret_version.hmcts_cloudgateway_bgp_auth_key.secret_string
#   customer_address = "169.254.88.5/30"
#   dx_gateway_id    = aws_dx_gateway.hmcts_gateway.id
#   sitelink_enabled = false
#   vlan             = "354"
# }
