locals {
  em_shift_schedule_start = "2026-10-05T09:00:00+01:00"
  em_heo_shadow_until     = "2026-10-12T09:00:00+01:00"

  # Set this when the career-break return date is confirmed.
  # A null value keeps the member out of the shift-based rota.
  em_career_break_return_at = null

  users_em = [
    {
      key   = "member_01"
      name  = "Gwion Aprhobat"
      email = "gwion.aprhobat@justice.gov.uk"
      grade = "g6"
      role  = "manager"

      rota = {
        working_pattern = "mon_thu"

        primary = {
          enabled     = true
          from        = local.em_shift_schedule_start
          until       = null
          cadence     = "fortnightly"
          cadence_day = "wednesday"
        }

        shadow = {
          enabled = false
          from    = null
          until   = null
          days    = []
        }

        absences = []
      }
    },
    {
      key   = "member_02"
      name  = "Matt Heery"
      email = "matt.heery@justice.gov.uk"
      grade = "g7"
      role  = "manager"

      rota = {
        working_pattern = "full_time"

        primary = {
          enabled     = true
          from        = local.em_shift_schedule_start
          until       = null
          cadence     = "standard"
          cadence_day = null
        }

        shadow = {
          enabled = false
          from    = null
          until   = null
          days    = []
        }

        absences = []
      }
    },
    {
      key   = "member_03"
      name  = "Matthew Rixson"
      email = "matthew.rixson@justice.gov.uk"
      grade = "g7"
      role  = "manager"

      rota = {
        working_pattern = "full_time"

        primary = {
          enabled     = true
          from        = local.em_shift_schedule_start
          until       = null
          cadence     = "standard"
          cadence_day = null
        }

        shadow = {
          enabled = false
          from    = null
          until   = null
          days    = []
        }

        absences = []
      }
    },
    {
      key   = "member_04"
      name  = "Khristiania Raihan"
      email = "khristiania.raihan@justice.gov.uk"
      grade = "seo"
      role  = "manager"

      rota = {
        working_pattern = "full_time"

        primary = {
          enabled     = true
          from        = local.em_shift_schedule_start
          until       = null
          cadence     = "standard"
          cadence_day = null
        }

        shadow = {
          enabled = false
          from    = null
          until   = null
          days    = []
        }

        absences = []
      }
    },
    {
      key   = "member_05"
      name  = "Lucy AstleyJones"
      email = "lucy.astleyjones@justice.gov.uk"
      grade = "seo"
      role  = "responder"

      rota = {
        working_pattern = "full_time"

        primary = {
          enabled     = true
          from        = local.em_shift_schedule_start
          until       = null
          cadence     = "standard"
          cadence_day = null
        }

        shadow = {
          enabled = false
          from    = null
          until   = null
          days    = []
        }

        absences = [
          {
            from  = local.em_shift_schedule_start
            until = local.em_career_break_return_at
          },
        ]
      }
    },
    {
      key   = "member_06"
      name  = "George Kelly"
      email = "george.kelly@justice.gov.uk"
      grade = "heo"
      role  = "responder"

      rota = {
        working_pattern = "full_time"

        primary = {
          enabled     = true
          from        = local.em_heo_shadow_until
          until       = null
          cadence     = "standard"
          cadence_day = null
        }

        shadow = {
          enabled = true
          from    = local.em_shift_schedule_start
          until   = local.em_heo_shadow_until

          days = [
            "monday",
            "wednesday",
            "friday",
          ]
        }

        absences = []
      }
    },
  ]

  teams_em = {
    "EM Data Hub Engineers" = {
      members = {
        for user in local.users_em :
        user.email => {
          name = user.name
          id   = module.users_em[user.email].id
          role = user.role
        }
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

  source = "./modules/team_em"

  name    = each.key
  members = each.value.members

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

moved {
  from = module.teams_em["EM Data Hub Engineers"].pagerduty_team_membership.managers["matt.heery@justice.gov.uk"]
  to   = module.teams_em["EM Data Hub Engineers"].pagerduty_team_membership.responders["matt.heery@justice.gov.uk"]
}

moved {
  from = module.teams_em["EM Data Hub Engineers"].pagerduty_team_membership.managers["khristiania.raihan@justice.gov.uk"]
  to   = module.teams_em["EM Data Hub Engineers"].pagerduty_team_membership.responders["khristiania.raihan@justice.gov.uk"]
}

# Keep the existing import blocks exactly as they are on the current branch.
# The email address inside each address must continue to match its PagerDuty ID.

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
    "gwion.aprhobat@justice.gov.uk"
  ].pagerduty_user.this

  id = "PY6LVCP"
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
