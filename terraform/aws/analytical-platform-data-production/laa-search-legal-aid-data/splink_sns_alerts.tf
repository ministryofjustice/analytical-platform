# Minimal SNS subscription + unauthorized-access metric filter/alarm

# SNS subscription for S3 alerts - requires manual email confirmation
resource "aws_sns_topic_subscription" "splink_bucket_alerts_email" {
  topic_arn = aws_sns_topic.splink_bucket_alerting_topic.arn
  protocol  = "email"
  endpoint  = var.splink_alert_email
}

# Metric filter for CloudTrail - unauthorized S3 calls
resource "aws_cloudwatch_log_metric_filter" "unauthorized_s3_calls" {
  name           = "splink-unauthorized-s3-calls"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name      = "UnauthorizedAPICallsEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }

  depends_on = [aws_cloudwatch_log_group.cloudtrail_logs]
}

# Simple CloudWatch Alarm for unauthorized access events
resource "aws_cloudwatch_metric_alarm" "s3_unauthorized_access" {
  alarm_name          = "splink-s3-unauthorized-access-attempts"
  alarm_description   = "Alert on unauthorized S3 access attempts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAPICallsEventCount"
  namespace           = "CloudTrailMetrics"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_actions       = [aws_sns_topic.splink_bucket_alerting_topic.arn]
  treat_missing_data  = "notBreaching"

  depends_on = [aws_cloudtrail.splink_s3_trail]
}
