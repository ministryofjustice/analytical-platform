resource "aws_s3_bucket" "opg_entra_fabric" {
  bucket = "alpha-opg-entra"

  tags = {
    Name        = "alpha-opg-entra"
    Environment = "sandbox"
  }
}