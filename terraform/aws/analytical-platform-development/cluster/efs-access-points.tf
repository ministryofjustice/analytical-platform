##################################################
# EKS User Homes
##################################################

resource "aws_efs_access_point" "eks_user_homes" {
  #checkov:skip=CKV_AWS_329: requires a destroy to implement
  #checkov:skip=CKV_AWS_330: requires ClientRootAccess IAM permission to implement
  file_system_id = aws_efs_file_system.eks_user_homes.id

  tags = {
    Name = "eks-${var.environment}-user-homes"
  }
}
