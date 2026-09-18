locals {
  users_em = [
    {
      name  = "Matt Heery"
      email = "matt.heery@justice.gov.uk"
      role  = "manager"
    },
    {
      name  = "Khristiania Raihan"
      email = "khristiania.raihan@justice.gov.uk"
      role  = "manager"
    },
    {
      name  = "Lucy AstleyJones"
      email = "lucy.astleyjones@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Matthew Rixson"
      email = "matthew.rixson@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Gwion Aprhobat"
      email = "gwion.aprhobat@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "George Kelly"
      email = "george.kelly@justice.gov.uk"
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
          name = "Layer 1"

          start = "2026-06-15T10:38:54+01:00"

          rotation_virtual_start = (
            "2026-06-15T09:00:00+01:00"
          )

          rotation_turn_length_seconds = 28800

          users = [
            for user in local.users_em :
            module.users_em[user.email].id
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

# The existing team membership for this person was previously managed
# as a responder. Preserve the same PagerDuty membership while moving
# Terraform management to the managers resource.

moved {
  from = module.teams_em[
    "EM Data Hub Engineers"
    ].pagerduty_team_membership.responders[
    "matt.heery@justice.gov.uk"
  ]

  to = module.teams_em[
    "EM Data Hub Engineers"
    ].pagerduty_team_membership.managers[
    "matt.heery@justice.gov.uk"
  ]
}

moved {
  from = module.teams_em[
    "EM Data Hub Engineers"
    ].pagerduty_team_membership.responders[
    "khristiania.raihan@justice.gov.uk"
  ]

  to = module.teams_em[
    "EM Data Hub Engineers"
    ].pagerduty_team_membership.managers[
    "khristiania.raihan@justice.gov.uk"
  ]
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
    "khristiania.raihan@justice.gov.uk"
  ].pagerduty_user.this

  id = "PSYDXO9"
}

import {
  to = module.users_em[
    "lucy.astleyjones@justice.gov.uk"
  ].pagerduty_user.this

  id = "PLV2QS6"
}

import {
  to = module.users_em[
    "matthew.rixson@justice.gov.uk"
  ].pagerduty_user.this

  id = "PREPU2L"
}
import {
  to = module.users_em[
    "gwion.aprhobat@digital.justice.gov.uk"
  ].pagerduty_user.this

  id = "PSXFTII"
}

import {
  to = module.users_em[
    "george.kelly@justice.gov.uk"
  ].pagerduty_user.this

  id = "PO9DYMA"
}

import {
  to = module.teams_em[
    "EM Data Hub Engineers"
  ].pagerduty_team.this

  id = "PCCDC5B"
}

import {
  to = module.schedules_em[
    "EM Data Hub Rota"
  ].pagerduty_schedule.this

  id = "P3MCA8L"
}
