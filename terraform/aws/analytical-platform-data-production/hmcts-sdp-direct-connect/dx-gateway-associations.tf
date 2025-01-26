# resource "aws_dx_gateway_association" "hmcts_gateway_airflow_dev" {
#   dx_gateway_id         = aws_dx_gateway.hmcts_gateway.id
#   associated_gateway_id = data.aws_vpn_gateway.airflow_dev.id
#   allowed_prefixes      = [data.aws_vpc.airflow_dev.cidr_block]
# }

# resource "aws_dx_gateway_association" "hmcts_gateway_airflow_prod" {
#   dx_gateway_id         = aws_dx_gateway.hmcts_gateway.id
#   associated_gateway_id = data.aws_vpn_gateway.airflow_prod.id
#   allowed_prefixes      = [data.aws_vpc.airflow_prod.cidr_block]
# }
