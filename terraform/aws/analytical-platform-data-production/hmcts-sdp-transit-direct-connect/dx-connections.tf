resource "aws_dx_connection" "hmcts_mojap" {
  name      = "HMCTS-MOJAP"
  location  = "TCSH"
  bandwidth = "200Mbps"
}

resource "aws_dx_connection" "hmcts_mojap_sec" {
  name      = "HMCTS MOJAP SEC"
  location  = "EqLD5"
  bandwidth = "200Mbps"
}
