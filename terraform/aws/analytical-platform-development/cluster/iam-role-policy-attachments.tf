##################################################
# EKS Worker CloudWatch Agent
##################################################

resource "aws_iam_role_policy_attachment" "eks_worker_cloudwatch_agent" {
  role       = module.eks.worker_iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

##################################################
# Bedrock Batch Inference
##################################################

resource "aws_iam_role_policy_attachment" "bedrock_integration_attachment" {
  role       = aws_iam_role.bedrock_batch_inference_role.name
  policy_arn = aws_iam_policy.bedrock_integration.arn
}
