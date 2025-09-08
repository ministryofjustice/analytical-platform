# Execution role for EventBridge Scheduler
resource "aws_iam_role" "scheduler_dms_role" {
  name = "eventbridge-scheduler-dms-dev"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "scheduler.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

# permissions for DMS task
resource "aws_iam_role_policy" "scheduler_dms_policy" {
  name = "eventbridge-scheduler-dms-dev"
  role = aws_iam_role.scheduler_dms_role.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "dms:StartReplicationTask",
        "dms:StopReplicationTask"
      ],
      Resource = var.dms_task_arn
    }]
  })
}

# Stop DMS task — Monday 13:00 UK time (later need to change to weekend for preprod)
resource "aws_scheduler_schedule" "dms_stop_mon_13" {
  name                         = "dms-stop-thu-1pm-uk-dev"
  description                  = "Stop DMS replication task every Thu 17:00 UK"
  schedule_expression          = "cron(0 13 ? * 2 *)"
  schedule_expression_timezone = "Europe/London"
  state                        = "ENABLED"

  flexible_time_window { mode = "OFF" }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:dms:stopReplicationTask"
    role_arn = aws_iam_role.scheduler_dms_role.arn
    input    = jsonencode({ ReplicationTaskArn = var.dms_task_arn })
  }

}

# Start DMS task — Thursdays 13:30 UK time (later need to change to weekend for preprod)
resource "aws_scheduler_schedule" "dms_start_thu_1330" {
  name                         = "dms-start-thu-1-30pm-uk-dev"
  description                  = "Start DMS replication task every Thu 13:30 UK"
  schedule_expression          = "cron(30 13 ? * 2 *)"
  schedule_expression_timezone = "Europe/London"
  state                        = "ENABLED"

  flexible_time_window { mode = "OFF" }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:dms:startReplicationTask"
    role_arn = aws_iam_role.scheduler_dms_role.arn
    input = jsonencode({
      ReplicationTaskArn       = var.dms_task_arn
      StartReplicationTaskType = "resume-processing"
    })
  }

}
