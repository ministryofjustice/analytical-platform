##################################################
# EKS User Homes
##################################################

resource "aws_efs_access_point" "eks_user_homes" {
  file_system_id = aws_efs_file_system.eks_user_homes.id

  tags = {
    Name = "eks-${var.environment}-user-homes"
  }
}
