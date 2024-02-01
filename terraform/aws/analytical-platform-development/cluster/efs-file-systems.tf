##################################################
# EKS User Homes
##################################################

resource "aws_efs_file_system" "eks_user_homes" {
  #checkov:skip=CKV_AWS_42: requires a destroy to implement
  #checkov:skip=CKV_AWS_184: dependant on implementation of CKV_AWS_42
  creation_token   = local.efs_file_system_name
  performance_mode = var.efs_file_system_performance_mode
  throughput_mode  = var.efs_file_system_throughput_mode

  tags = {
    Name = local.efs_file_system_name
  }
}
