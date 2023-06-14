##################################################
# EKS User Homes
##################################################

resource "aws_efs_file_system" "eks_user_homes" {
  creation_token   = local.efs_file_system_name
  performance_mode = var.efs_file_system_performance_mode
  throughput_mode  = var.efs_file_system_throughput_mode

  tags = {
    Name = local.efs_file_system_name
  }
}
