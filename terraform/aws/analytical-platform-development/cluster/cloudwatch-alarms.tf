##################################################
# NAT Gateway Alarms
##################################################

resource "aws_cloudwatch_metric_alarm" "nat_gateway_bandwidth" {
  for_each = toset(data.aws_nat_gateways.nat_gateways.ids)

  alarm_name                = "nat-gateway-${each.value}-high-bandwidth"
  comparison_operator       = "GreaterThanThreshold"
  threshold                 = var.nat_gateway_bandwidth_alarm_threshold
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  alarm_description         = "NAT Gateway bandwidth usage is high"
  alarm_actions             = [aws_sns_topic.analytical_platform_networking_alerts.arn]
  ok_actions                = [aws_sns_topic.analytical_platform_networking_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.analytical_platform_networking_alerts.arn]

  metric_query {
    id          = "in1"
    return_data = false
    metric {
      namespace   = "AWS/NATGateway"
      metric_name = "BytesInFromDestination"
      stat        = "Sum"
      period      = 60
      dimensions = {
        NatGatewayId = each.value
      }
    }
  }

  metric_query {
    id          = "in2"
    return_data = false
    metric {
      namespace   = "AWS/NATGateway"
      metric_name = "BytesInFromSource"
      stat        = "Sum"
      period      = 60
      dimensions = {
        NatGatewayId = each.value
      }
    }
  }

  metric_query {
    id          = "in2"
    return_data = false
    metric {
      namespace   = "AWS/NATGateway"
      metric_name = "BytesInFromSource"
      stat        = "Sum"
      period      = 60
      dimensions = {
        NatGatewayId = each.value
      }
    }
  }

  metric_query {
    id          = "out1"
    return_data = false
    metric {
      namespace   = "AWS/NATGateway"
      metric_name = "BytesOutToDestination"
      stat        = "Sum"
      period      = 60
      dimensions = {
        NatGatewayId = each.value
      }
    }
  }

  metric_query {
    id          = "out2"
    return_data = false
    metric {
      namespace   = "AWS/NATGateway"
      metric_name = "BytesOutToSource"
      stat        = "Sum"
      period      = 60
      dimensions = {
        NatGatewayId = each.value
      }
    }
  }

  metric_query {
    id          = "bandwidth"
    return_data = false
    expression  = "(in1+in2+out1+out2)/60*8/1000/1000/1000"
  }

  metric_query {
    id          = "utilisation"
    return_data = true
    expression  = "bandwidth/100*100"
  }
}

##################################################
# EFS Alarms
##################################################

resource "aws_cloudwatch_metric_alarm" "efs_low_credit_burst_balance" {
  alarm_name                = "efs-low-credit-burst-balance"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "BurstCreditBalance"
  namespace                 = "AWS/EFS"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = var.efs_low_credit_burst_balance_alarm_threshold
  alarm_description         = "Average burst credit balance over last 10 minutes too low, expect a significant performance drop soon"
  alarm_actions             = [aws_sns_topic.analytical_platform_storage_alerts.arn]
  ok_actions                = [aws_sns_topic.analytical_platform_storage_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.analytical_platform_storage_alerts.arn]

  dimensions = {
    FileSystemId = aws_efs_file_system.eks_user_homes.id
  }
}

##################################################
# RDS Alarms
##################################################

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu_utilisation" {
  alarm_name                = "rds-${local.rds_identifier}-high-cpu-utilisation"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = var.rds_high_cpu_utilisation_alarm_threshold
  alarm_description         = "Average database CPU utilisation is too high."
  alarm_actions             = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  ok_actions                = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.analytical_platform_compute_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_low_cpu_credit_balance" {
  alarm_name                = "rds-${local.rds_identifier}-low-cpu-credit-balance"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUCreditBalance"
  namespace                 = "AWS/RDS"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = var.rds_low_cpu_credit_balance_alarm_threshold
  alarm_description         = "Average database CPU credit balance is too low, a negative performance impact is imminent."
  alarm_actions             = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  ok_actions                = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.analytical_platform_compute_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_disk_queue_depth" {
  alarm_name                = "rds-${local.rds_identifier}-high-disk-queue-depth"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "DiskQueueDepth"
  namespace                 = "AWS/RDS"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = var.rds_high_disk_queue_depth_alarm_threshold
  alarm_description         = "Average database disk queue depth is too high, performance may be negatively impacted."
  alarm_actions             = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  ok_actions                = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.analytical_platform_compute_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_low_free_storage_space" {
  alarm_name                = "rds-${local.rds_identifier}-low-free-storage-space"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "FreeStorageSpace"
  namespace                 = "AWS/RDS"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = var.rds_low_free_storage_space_alarm_threshold
  alarm_description         = "Average database free storage space is too low and may fill up soon."
  alarm_actions             = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  ok_actions                = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.analytical_platform_compute_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_low_disk_burst_balance" {
  alarm_name                = "rds-${local.rds_identifier}-low-disk-burst-balance"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "BurstBalance"
  namespace                 = "AWS/RDS"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = var.rds_low_disk_burst_balance_alarm_threshold
  alarm_description         = "Average database storage burst balance is too low, a negative performance impact is imminent."
  alarm_actions             = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  ok_actions                = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.analytical_platform_compute_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_low_freeable_memory" {
  alarm_name                = "rds-${local.rds_identifier}-low-freeable-memory"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "FreeableMemory"
  namespace                 = "AWS/RDS"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = var.rds_low_freeable_memory_alarm_threshold
  alarm_description         = "Average database freeable memory is too low, performance may be negatively impacted."
  alarm_actions             = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  ok_actions                = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.analytical_platform_compute_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_swap_usage" {
  alarm_name                = "rds-${local.rds_identifier}-high-swap-usage"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "SwapUsage"
  namespace                 = "AWS/RDS"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = var.rds_high_swap_usage_alarm_threshold
  alarm_description         = "Average database swap usage is too high, performance may be negatively impacted."
  alarm_actions             = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  ok_actions                = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.analytical_platform_compute_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = local.rds_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_anamalous_connection_count" {
  alarm_name                = "rds-${local.rds_identifier}-anamalous-connection-count"
  comparison_operator       = "GreaterThanUpperThreshold"
  evaluation_periods        = "5"
  threshold_metric_id       = "e1"
  alarm_description         = "Anomalous database connection count detected. Something unusual is happening."
  alarm_actions             = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  ok_actions                = [aws_sns_topic.analytical_platform_compute_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.analytical_platform_compute_alerts.arn]

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "DatabaseConnections (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "DatabaseConnections"
      namespace   = "AWS/RDS"
      period      = "600"
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        DBInstanceIdentifier = local.rds_identifier
      }
    }
  }
}
