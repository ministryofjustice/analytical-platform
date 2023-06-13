##################################################
# EKS User Homes
##################################################

resource "aws_efs_mount_target" "eks_user_homes" {
  count = length(module.vpc.private_subnets)

  file_system_id  = aws_efs_file_system.eks_user_homes.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}
