##################################################
# Control Panel Alerts - PagerDuty
# TODO: Replace with Analytics Platform Generic
##################################################

resource "aws_sns_topic_subscription" "control_panel_alerts_pagerduty" {
  topic_arn              = aws_sns_topic.control_panel_alerts.arn
  protocol               = "https"
  endpoint               = local.pagerduty_analytical_platform_compute_endpoint
  endpoint_auto_confirms = true
}

##################################################
# Compute Alerts - PagerDuty
##################################################

resource "aws_sns_topic_subscription" "analytical_platform_compute_alerts_pagerduty" {
  topic_arn              = aws_sns_topic.analytical_platform_compute_alerts.arn
  protocol               = "https"
  endpoint               = local.pagerduty_analytical_platform_compute_endpoint
  endpoint_auto_confirms = true
}

##################################################
# Networking Alerts - PagerDuty
##################################################

resource "aws_sns_topic_subscription" "analytical_platform_networking_alerts_pagerduty" {
  topic_arn              = aws_sns_topic.analytical_platform_networking_alerts.arn
  protocol               = "https"
  endpoint               = local.pagerduty_analytical_platform_networking_endpoint
  endpoint_auto_confirms = true
}

##################################################
# Networking Alerts - PagerDuty
##################################################

resource "aws_sns_topic_subscription" "analytical_platform_storage_alerts_pagerduty" {
  topic_arn              = aws_sns_topic.analytical_platform_storage_alerts.arn
  protocol               = "https"
  endpoint               = local.pagerduty_analytical_platform_storage_endpoint
  endpoint_auto_confirms = true
}
