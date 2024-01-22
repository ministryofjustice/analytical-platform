##################################################
# EFS Encryption Key
##################################################

resource "aws_kms_key" "sagemaker_cmk" {
  description = "EFS Secret Encryption Key for Sagemaker"
}
