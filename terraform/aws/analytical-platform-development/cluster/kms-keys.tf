##################################################
# EKS Encryption Key
##################################################

resource "aws_kms_key" "eks" {
  description         = "EKS Secret Encryption Key"
  enable_key_rotation = true
}
