##################################################
# EKS User Homes
##################################################

resource "aws_efs_access_point" "eks_user_homes" {
  #checkov:skip=CKV_AWS_330: skip - EFS access points should enforce a user identity
  #checkov:skip=CKV_AWS_329: skip - EFS access points should enforce a root directory
  #checkov:skip=CKV_AWS_184: skip - Ensure resource is encrypted by KMS using a customer managed Key (CMK)
  file_system_id = aws_efs_file_system.eks_user_homes.id

  tags = {
    Name = local.efs_file_system_name
  }
}
