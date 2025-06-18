locals {
  schedules_ae_loc = [
    {
      name = "Analytics Engineering Support SEO_HEO"
      team = module.teams_ae["Analytics Engineering Support SEO_HEO"].id
      layers = [
        {
          name                         = "AE Daily Support Rota SEO_HEO"
          start                        = "2023-03-27T09:00:00Z"
          rotation_virtual_start       = "2025-05-01T09:00:00+01:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users_ae_seo["owen.buckley@justice.gov.uk"].id,
            module.users_ae_seo["neil.wilkins@justice.gov.uk"].id
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
    },
    {
      name = "Analytics Engineering Support G7"
      team = module.teams_ae["Analytics Engineering Support G7"].id
      layers = [
        {
          name                         = "AE Daily Support Rota G7"
          start                        = "2023-03-27T09:00:00Z"
          rotation_virtual_start       = "2025-05-01T09:00:00+01:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users_ae_g7["alex.pavlopoulos@justice.gov.uk"].id,
            module.users_ae_g7["holly.furniss@justice.gov.uk"].id
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

  teams_ae = {
    "Analytics Engineering Support SEO_HEO" = {
      responders = {
        for user in local.users_ae_seo :
        user.email => {
          name = user.name
          id   = module.users_ae_seo[user.email].id
        }
        if user.role == "responder"
      }
    },
    "Analytics Engineering Support G7" = {
      responders = {
        for user in local.users_ae_g7 :
        user.email => {
          name = user.name
          id   = module.users_ae_g7[user.email].id
        }
        if user.role == "responder"
      }
    }
  }

  users_ae_seo = [
    {
      name  = "Owen Buckley"
      email = "owen.buckley@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Neil Wilkins"
      email = "neil.wilkins@justice.gov.uk"
      role  = "responder"
    }
  ]

  users_ae_g7 = [
    {
      name  = "Alex Pavlopoulos"
      email = "alex.pavlopoulos@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Holly Furniss"
      email = "holly.furniss@justice.gov.uk"
      role  = "responder"
    }
  ]
}

module "schedules_ae" {
  for_each = { for schedule in local.schedules_ae_loc : schedule.name => schedule }

  source = "./modules/schedule"
  name   = each.key
  team   = each.value.team
  layers = each.value.layers

  depends_on = [module.teams_ae]
}

module "teams_ae" {
  for_each = local.teams_ae

  source     = "./modules/team"
  name       = each.key
  responders = each.value.responders
  depends_on = [module.users_ae_seo, module.users_ae_g7]
}

module "users_ae_seo" {
  for_each = { for user in local.users_ae_seo : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.key
}

module "users_ae_g7" {
  for_each = { for user in local.users_ae_g7 : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.key
}

import {
  to = module.users_ae_seo["owen.buckley@justice.gov.uk"].pagerduty_user.this
  id = "PRTC0Q5"
}

import {
  to = module.users_ae_seo["neil.wilkins@justice.gov.uk"].pagerduty_user.this
  id = "PFUIUUH"
}

import {
  to = module.users_ae_g7["alex.pavlopoulos@justice.gov.uk"].pagerduty_user.this
  id = "PEMXSEN"
}

import {
  to = module.users_ae_g7["holly.furniss@justice.gov.uk"].pagerduty_user.this
  id = "PLVNCOV"
}
