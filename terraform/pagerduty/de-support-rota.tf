data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret" "pagerduty_token" {
  name = "pagerduty-token"
}

data "aws_secretsmanager_secret_version" "pagerduty_token" {
  secret_id = data.aws_secretsmanager_secret.pagerduty_token.id
}

locals {
  schedules = [
    {
      name = "Data Engineering Support"
      team = module.teams["Data Engineering Support Team"].id
      layers = [
        {
          name                         = "Daily Support Rota"
          start                        = "2023-03-27T09:00:00Z"
          rotation_virtual_start       = "2024-09-20T09:00:00+01:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users["guy.wheeler@justice.gov.uk"].id,
            module.users["thomas.hepworth@justice.gov.uk"].id,
          ]
          restrictions = [
            {
              type              = "weekly_restriction"
              start_day_of_week = 1
              start_time_of_day = "09:00:00"
              duration_seconds  = 28800
            },
            {
              type              = "weekly_restriction"
              start_day_of_week = 2
              start_time_of_day = "09:00:00"
              duration_seconds  = 28800
            },
            {
              type              = "weekly_restriction"
              start_day_of_week = 3
              start_time_of_day = "09:00:00"
              duration_seconds  = 28800
            },
            {
              type              = "weekly_restriction"
              start_day_of_week = 4
              start_time_of_day = "09:00:00"
              duration_seconds  = 28800
            },
            {
              type              = "weekly_restriction"
              start_day_of_week = 5
              start_time_of_day = "09:00:00"
              duration_seconds  = 28800
            }
          ]
        }
      ]
    }
  ]
}

module "schedules-de" {
  for_each = { for schedule in local.schedules : schedule.name => schedule }

  source = "../modules/schedules-de"
  name   = each.key
  team   = each.value.team
  layers = each.value.layers

  depends_on = [module.teams-de]
}

locals {
  teams-de = {
    "Data Engineering Support Team" = {
      responders = {
        for user in local.users-de :
        user.email => {
          name = user.name
          id   = module.users[user.email].id
        }
        if user.role == "responder"
      }
    }
  }
}

module "teams-de" {
  for_each = local.teamsteams-de

  source     = "../modules/team"
  name       = each.key
  responders = each.value.responders
  depends_on = [module.users]
}

locals {
  users-de = [
    {
      name  = "Guy Wheeler"
      email = "guy.wheeler@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Thomas Hepworth"
      email = "thomas.hepworth@justice.gov.uk"
      role  = "responder"
    }
  ]
}

module "users-de" {
  for_each = { for user in local.users-de : user.email => user }

  source = "../modules/user"
  name   = each.value.name
  email  = each.key
}
