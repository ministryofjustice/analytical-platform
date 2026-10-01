locals {
  em_shift_schedule_start = "2026-10-05T09:00:00+01:00"
  em_heo_shadow_until     = "2026-10-12T09:00:00+01:00"

  # Set this when the career-break return date is confirmed.
  #
  # Example:
  # em_career_break_return_at = "2027-03-01T09:00:00+00:00"
  #
  # Leaving this as null keeps the SEO out of the new shift-based rota
  # while keeping their PagerDuty account and team membership.
  em_career_break_return_at = null

  # ---------------------------------------------------------------------------
  # EM team members
  # ---------------------------------------------------------------------------
  #
  # key
  #   Stable internal Terraform identifier.
  #
  # grade
  #   Organisational grade.
  #
  # role
  #   PagerDuty team role.
  #
  # rota.working_pattern
  #   Normal working availability.
  #
  # rota.primary
  #   Primary rota participation.
  #
  # rota.shadow
  #   Additional shadow coverage.
  #
  # rota.absences
  #   Planned long-term absence from the primary rota.
  #
  users_em = [
    {
      key   = "member_01"
      name  = "G6_NAME"
      email = "G6_EMAIL"
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
      name  = "G7_1_NAME"
      email = "G7_1_EMAIL"
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
      name  = "G7_2_NAME"
      email = "G7_2_EMAIL"
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
      name  = "SEO_MANAGER_NAME"
      email = "SEO_MANAGER_EMAIL"
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
      name  = "SEO_RESPONDER_NAME"
      email = "SEO_RESPONDER_EMAIL"
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
      name  = "HEO_NAME"
      email = "HEO_EMAIL"
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

  # ---------------------------------------------------------------------------
  # Legacy schedule order
  # ---------------------------------------------------------------------------
  #
  # P3MCA8L is still used by the existing EM Lambda integrations.
  #
  # Keep this list in the exact order currently held by PagerDuty.
  # Do not derive the legacy schedule order from users_em.
  #
  # Existing PagerDuty order:
  #
  #   1. PEYIF4Q
  #   2. PSYDXO9
  #   3. PLV2QS6
  #   4. PREPU2L
  #   5. PY6LVCP
  #   6. PO9DYMA
  #
  em_legacy_schedule_user_emails = [
    "EMAIL_FOR_PEYIF4Q",
    "EMAIL_FOR_PSYDXO9",
    "EMAIL_FOR_PLV2QS6",
    "EMAIL_FOR_PREPU2L",
    "G6_EMAIL",
    "EMAIL_FOR_PO9DYMA",
  ]

  # ---------------------------------------------------------------------------
  # PagerDuty team
  # ---------------------------------------------------------------------------

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

  # ---------------------------------------------------------------------------
  # Legacy PagerDuty schedule
  # ---------------------------------------------------------------------------
  #
  # Keep this schedule unchanged until the EM Lambda consumers have moved
  # from the PagerDuty V2 schedule API to the new shift-based schedule.
  #
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
            for email in local.em_legacy_schedule_user_emails :
            module.users_em[email].id
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

# -----------------------------------------------------------------------------
# PagerDuty users
# -----------------------------------------------------------------------------

module "users_em" {
  for_each = {
    for user in local.users_em :
    user.email => user
  }

  source = "./modules/user"

  name  = each.value.name
  email = each.value.email
}

# -----------------------------------------------------------------------------
# PagerDuty team
# -----------------------------------------------------------------------------

module "teams_em" {
  for_each = local.teams_em

  source = "./modules/team_em"

  name    = each.key
  members = each.value.members

  depends_on = [module.users_em]
}

# -----------------------------------------------------------------------------
# Legacy PagerDuty schedule
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Historical Terraform state moves
# -----------------------------------------------------------------------------
#
# Keep the existing real manager email addresses already present on the branch.
# These historical moves allow older Terraform state addresses to reach the
# current team_em membership resource without destroying memberships.
#

moved {
  from = module.teams_em["EM Data Hub Engineers"].pagerduty_team_membership.managers["MANAGER_1_EMAIL"]
  to   = module.teams_em["EM Data Hub Engineers"].pagerduty_team_membership.responders["MANAGER_1_EMAIL"]
}

moved {
  from = module.teams_em["EM Data Hub Engineers"].pagerduty_team_membership.managers["MANAGER_2_EMAIL"]
  to   = module.teams_em["EM Data Hub Engineers"].pagerduty_team_membership.responders["MANAGER_2_EMAIL"]
}

# -----------------------------------------------------------------------------
# Existing PagerDuty resources
# -----------------------------------------------------------------------------
#
# Keep each email associated with the same PagerDuty user ID.
#

import {
  to = module.users_em[
    "EMAIL_FOR_PEYIF4Q"
  ].pagerduty_user.this

  id = "PEYIF4Q"
}

import {
  to = module.users_em[
    "EMAIL_FOR_PSYDXO9"
  ].pagerduty_user.this

  id = "PSYDXO9"
}

import {
  to = module.users_em[
    "EMAIL_FOR_PLV2QS6"
  ].pagerduty_user.this

  id = "PLV2QS6"
}

import {
  to = module.users_em[
    "EMAIL_FOR_PREPU2L"
  ].pagerduty_user.this

  id = "PREPU2L"
}

import {
  to = module.users_em[
    "G6_EMAIL"
  ].pagerduty_user.this

  id = "PY6LVCP"
}

import {
  to = module.users_em[
    "EMAIL_FOR_PO9DYMA"
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
