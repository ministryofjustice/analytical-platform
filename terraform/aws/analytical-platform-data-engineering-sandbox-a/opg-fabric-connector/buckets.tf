resource "aws_s3_bucket" "opg_fabric_store" {
  bucket = "alpha-opg-fabric"

  tags = {
    Name = "alpha-opg-fabric"
  }
}
