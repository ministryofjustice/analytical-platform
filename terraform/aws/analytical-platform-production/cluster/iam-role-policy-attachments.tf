##################################################
# EKS Worker CloudWatch Agent
##################################################

resource "aws_iam_role_policy_attachment" "eks_worker_cloudwatch_agent" {
  role       = module.eks.worker_iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
