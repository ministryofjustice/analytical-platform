# Execution role for EventBridge Scheduler

resource "aws_iam_role" "scheduler_dms_role" {
  name = "eventbridge-scheduler-dms-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
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
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "dms:StartReplicationTask",
        "dms:StopReplicationTask"
      ],
      Resource = module.dev_dms_oasys.dms_cdc_task_arn
    }]
  })
}

# Stop DMS task — Monday 14:00 UK time (later need to change to weekend for preprod)
resource "aws_scheduler_schedule" "dms_stop_tue_1130" {
  name                         = "dms-stop-tue-11-30am-uk-dev"
  description                  = "Stop DMS replication task every tue 11:30 UK"
  schedule_expression          = "cron(30 11 ? * 3 *)"
  schedule_expression_timezone = "Europe/London"
  state                        = "ENABLED"

  flexible_time_window { mode = "OFF" }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:databasemigration:stopReplicationTask"
    role_arn = aws_iam_role.scheduler_dms_role.arn
    input    = jsonencode({ ReplicationTaskArn = module.dev_dms_oasys.dms_cdc_task_arn })
  }

}

# Start DMS task — Thursdays 13:30 UK time (later need to change to weekend for preprod)
resource "aws_scheduler_schedule" "dms_start_mon_1700" {
  name                         = "dms-start-tue-12pm-uk-dev"
  description                  = "Start DMS replication task every tue 12:00 UK"
  schedule_expression          = "cron(0 12 ? * 3 *)"
  schedule_expression_timezone = "Europe/London"
  state                        = "ENABLED"

  flexible_time_window { mode = "OFF" }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:databasemigration:startReplicationTask"
    role_arn = aws_iam_role.scheduler_dms_role.arn
    input = jsonencode({
      ReplicationTaskArn       = module.dev_dms_oasys.dms_cdc_task_arn,
      StartReplicationTaskType = "resume-processing"
    })
  }

}
