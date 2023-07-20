resource "random_password" "coder_rds_password" {
  length  = 32
  special = false
}
