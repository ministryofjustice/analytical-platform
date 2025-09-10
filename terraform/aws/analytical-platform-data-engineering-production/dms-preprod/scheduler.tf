data "aws_iam_policy_document" "sfn_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sfn_dms_role" {
  name               = "sfn-dms-control-role-preprod"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "sfn_dms_policy" {
  name = "sfn-dms-allow-preprod"
  role = aws_iam_role.sfn_dms_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["dms:StartReplicationTask", "dms:StopReplicationTask"],
        Resource = module.preprod_dms_oasys.dms_cdc_task_arn
      }
    ]
  })
}

resource "aws_sfn_state_machine" "dms_control" {
  name     = "dms-control-preprod"
  role_arn = aws_iam_role.sfn_dms_role.arn
  tags     = var.tags

  definition = jsonencode({
    Comment = "Stop or restart DMS CDC task with dynamic CDC start time",
    StartAt = "ChooseOp",
    States = {
      ChooseOp = {
        Type = "Choice",
        Choices = [
          { Variable = "$.Op", StringEquals = "stop", Next = "Stop" },
          { Variable = "$.Op", StringEquals = "start", Next = "Start" }
        ],
        Default = "FailOp"
      },
      Stop = {
        Type     = "Task",
        Resource = "arn:aws:states:::aws-sdk:databasemigration:stopReplicationTask",
        Parameters = {
          "ReplicationTaskArn.$" = "$.ReplicationTaskArn"
        },
        End = true
      },
      Start = {
        Type     = "Task",
        Resource = "arn:aws:states:::aws-sdk:databasemigration:startReplicationTask",
        Parameters = {
          "ReplicationTaskArn.$"     = "$.ReplicationTaskArn",
          "StartReplicationTaskType" = "start-replication",
          "CdcStartTime.$"           = "$$.Execution.StartTime"
        },
        End = true
      },
      FailOp = { Type = "Fail", Error = "InvalidOp", Cause = "Op must be 'start' or 'stop'." }
    }
  })
}

resource "aws_iam_role" "scheduler_role" {
  name = "eventbridge-scheduler-dms-preprod-sm"
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

resource "aws_iam_role_policy" "scheduler_start_sfn" {
  name = "scheduler-start-sfn-preprod"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["states:StartExecution"],
      Resource = aws_sfn_state_machine.dms_control.arn
    }]
  })
}

resource "aws_scheduler_schedule" "dms_stop_sun_0300" {
  name                         = "dms-stop-sun-3am-uk-preprod"
  description                  = "Stop DMS CDC every Sunday 03:00 UK"
  schedule_expression          = "cron(0 3 ? * SUN *)"
  schedule_expression_timezone = "Europe/London"
  state                        = "ENABLED"
  flexible_time_window { mode = "OFF" }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:sfn:startExecution"
    role_arn = aws_iam_role.scheduler_role.arn
    input = jsonencode({
      StateMachineArn = aws_sfn_state_machine.dms_control.arn,
      Input = jsonencode({
        Op                 = "stop",
        ReplicationTaskArn = module.preprod_dms_oasys.dms_cdc_task_arn
      })
    })
  }
}

resource "aws_scheduler_schedule" "dms_start_sun_1900" {
  name                         = "dms-start-sun-7pm-uk-preprod"
  description                  = "Restart DMS CDC every Sunday 19:00 UK"
  schedule_expression          = "cron(0 19 ? * SUN *)"
  schedule_expression_timezone = "Europe/London"
  state                        = "ENABLED"
  flexible_time_window { mode = "OFF" }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:sfn:startExecution"
    role_arn = aws_iam_role.scheduler_role.arn
    input = jsonencode({
      StateMachineArn = aws_sfn_state_machine.dms_control.arn,
      Input = jsonencode({
        Op                 = "start",
        ReplicationTaskArn = module.preprod_dms_oasys.dms_cdc_task_arn
      })
    })
  }
}
