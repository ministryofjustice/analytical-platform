##################################################
# EKS User Homes
##################################################

resource "aws_efs_file_system" "eks_user_homes" {
  #checkov:skip=CKV_AWS_184: skip - Ensure resource is encrypted by KMS using a customer managed Key (CMK)
  #checkov:skip=CKV_AWS_42: skip - Ensure EFS is securely encrypted
  creation_token   = local.efs_file_system_name
  performance_mode = var.efs_file_system_performance_mode
  throughput_mode  = var.efs_file_system_throughput_mode

  tags = {
    Name = local.efs_file_system_name
  }
}
