locals {
  users_em = [
    {
      name  = "Matt Heery"
      email = "matt.heery@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Matthew Rixson"
      email = "matthew.rixson@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Lucy AstleyJones"
      email = "lucy.astleyjones@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Khristiania Raihan"
      email = "khristiania.raihan@justice.gov.uk"
      role  = "responder"
    },

  ]

  teams_em = {
    "EM Data Hub Engineers" = {
      responders = {
        for user in local.users_em :
        user.email => {
          name = user.name
          id   = module.users_em[user.email].id
        }
        if user.role == "responder"
      }
    }
  }

  schedules_em = [
    {
      name = "EM Data Hub Rota"
      team = module.teams_em["EM Data Hub Engineers"].id

      layers = [
        {
          name = "EM Daily Support Rota"

          start = "EXISTING_LAYER_START"

          rotation_virtual_start = (
            "EXISTING_ROTATION_VIRTUAL_START"
          )

          rotation_turn_length_seconds = 86400

          users = [
            for user in local.users_em :
            module.users_em[user.email].id
          ]

          restrictions = [
            {
              type              = "weekly_restriction"
              start_day_of_week = 1
              start_time_of_day = "00:00:00"
              duration_seconds  = 86400
            },
            {
              type              = "weekly_restriction"
              start_day_of_week = 2
              start_time_of_day = "00:00:00"
              duration_seconds  = 86400
            },
            {
              type              = "weekly_restriction"
              start_day_of_week = 3
              start_time_of_day = "00:00:00"
              duration_seconds  = 86400
            },
            {
              type              = "weekly_restriction"
              start_day_of_week = 4
              start_time_of_day = "00:00:00"
              duration_seconds  = 86400
            },
            {
              type              = "weekly_restriction"
              start_day_of_week = 5
              start_time_of_day = "00:00:00"
              duration_seconds  = 86400
            },
          ]
        },
      ]
    },
  ]
}

module "users_em" {
  for_each = {
    for user in local.users_em :
    user.email => user
  }

  source = "./modules/user"

  name  = each.value.name
  email = each.value.email
}

module "teams_em" {
  for_each = local.teams_em

  source = "./modules/team"

  name       = each.key
  responders = each.value.responders

  depends_on = [module.users_em]
}

module "schedules_em" {
  for_each = {
    for schedule in local.schedules_em :
    schedule.name => schedule
  }

  source = "./modules/schedule"

  name   = each.key
  team   = each.value.team
  layers = each.value.layers

  depends_on = [module.teams_em]
}

# Existing PagerDuty resources are imported so Terraform manages them
# instead of creating duplicates.

import {
  to = module.users_em[
    "matt.heery@justice.gov.uk"
  ].pagerduty_user.this

  id = "PEYIF4Q"
}

import {
  to = module.users_em[
    "matthew.rixson@justice.gov.uk"
  ].pagerduty_user.this

  id = "PREPU2L"
}

import {
  to = module.users_em[
    "lucy.astleyjones@justice.gov.uk"
  ].pagerduty_user.this

  id = "PLV2QS6"
}

import {
  to = module.users_em[
    "khristiania.raihan@justice.gov.uk"
  ].pagerduty_user.this

  id = "PSYDXO9"
}

import {
  to = module.teams_em[
    "EM Data Hub Engineers"
  ].pagerduty_team.this

  id = "P3MCA8L"
}

import {
  to = module.schedules_em[
    "EM Data Hub Rota"
  ].pagerduty_schedule.this

  id = "EM_SCHEDULE_PAGERDUTY_ID"
}