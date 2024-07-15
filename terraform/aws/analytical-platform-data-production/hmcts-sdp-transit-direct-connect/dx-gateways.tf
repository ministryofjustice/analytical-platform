resource "aws_dx_gateway" "hmcts_gateway" {
  name            = "HMCTS_Gateway"
  amazon_side_asn = "64512"
}
