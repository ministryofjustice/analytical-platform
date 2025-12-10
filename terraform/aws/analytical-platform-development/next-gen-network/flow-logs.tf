resource "aws_flow_log" "vpc" {
  iam_role_arn    = module.vpc_flow_logs_iam_role.arn
  log_destination = module.vpc_flow_logs_log_group.cloudwatch_log_group_arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${local.application_name}-${local.environment}-cloudwatch-logs"
  }
}
