locals {
  schedules_de_loc_dev = [
    {
      name = "Data Engineering Support HEO_SEO Dev"
      team = module.teams_de_dev["Data Engineering Support HEO_SEO Dev"].id
      layers = [
        {
          name                         = "DE Daily Support Rota HEO_SEO Mon Fri"
          start                        = "2023-03-27T09:00:00Z"
          rotation_virtual_start       = "2025-07-05T00:00:00+01:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users_de_seo_dev["murad.ali@justice.gov.uk"].id,
            module.users_de_seo_dev["andrew.cook@digital.justice.gov.uk"].id,
            module.users_de_seo_dev["anthony.cody@digital.justice.gov.uk"].id,
            module.users_de_seo_dev["thomas.hirsch@justice.gov.uk"].id,
            module.users_de_seo_dev["william.orr@digital.justice.gov.uk"].id,
            module.users_de_seo_dev["khristiania.raihan@justice.gov.uk"].id,
            module.users_de_seo_dev["mohammed.ahad1@justice.gov.uk"].id,
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
            }
          ]
        },
        {
          name                         = "DE Daily Support Rota HEO_SEO Mon Thur"
          start                        = "2023-03-27T09:00:00Z"
          rotation_virtual_start       = "2025-07-05T00:00:00+01:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users_de_seo_dev["guy.wheeler@justice.gov.uk"].id,
            module.users_de_seo_dev["siva.bathina@digital.justice.gov.uk"].id,
            module.users_de_seo_dev["murad.ali@justice.gov.uk"].id,
            module.users_de_seo_dev["andrew.cook@digital.justice.gov.uk"].id,
            module.users_de_seo_dev["anthony.cody@digital.justice.gov.uk"].id,
            module.users_de_seo_dev["thomas.hirsch@justice.gov.uk"].id,
            module.users_de_seo_dev["william.orr@digital.justice.gov.uk"].id,
            module.users_de_seo_dev["khristiania.raihan@justice.gov.uk"].id,
            module.users_de_seo_dev["mohammed.ahad1@justice.gov.uk"].id,
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
            }
          ]
        }
      ]
    },
    {
      name = "Data Engineering Support G7 Dev"
      team = module.teams_de["Data Engineering Support G7 Dev"].id
      layers = [
        {
          name                         = "DE Daily Support Rota G7 Dev"
          start                        = "2023-03-27T09:00:00Z"
          rotation_virtual_start       = "2025-07-04T09:00:00+01:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users_de_g7_dev["matt.heery@justice.gov.uk"].id,
            module.users_de_g7_dev["lalitha.nagarur3@justice.gov.uk"].id,
            module.users_de_g7_dev["matthew.price2@justice.gov.uk"].id,
            module.users_de_g7_dev["andrew.craik@justice.gov.uk"].id,
            module.users_de_g7_dev["supratik.chowdhury@digital.justice.gov.uk"].id,
            module.users_de_g7_dev["tapan.perkins@digital.justice.gov.uk"].id,
            module.users_de_g7_dev["thomas.hepworth@justice.gov.uk"].id,
            module.users_de_g7_dev["philip.sinfield@justice.gov.uk"].id,
            module.users_de_g7_dev["laurence.droy@justice.gov.uk"].id,
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

  teams_de_dev = {
    "Data Engineering Support HEO_SEO Dev" = {
      responders = {
        for user in local.users_de_seo :
        user.email => {
          name = user.name
          id   = module.users_de_seo[user.email].id
        }
        if user.role == "responder"
      }
    },
    "Data Engineering Support G7 Dev" = {
      responders = {
        for user in local.users_de_g7_dev :
        user.email => {
          name = user.name
          id   = module.users_de_g7[user.email].id
        }
        if user.role == "responder"
      }
    }
  }

  users_de_seo_dev = [
    {
      name  = "Guy Wheeler"
      email = "guy.wheeler@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Siva Bathina"
      email = "siva.bathina@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Murad Ali"
      email = "murad.ali@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Andrew Cook"
      email = "andrew.cook@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Anthony Cody"
      email = "anthony.cody@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Thomas Hirsch"
      email = "thomas.hirsch@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "William Orr"
      email = "william.orr@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Khristiania Raihan"
      email = "khristiania.raihan@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Mohammed Ahad"
      email = "mohammed.ahad1@justice.gov.uk"
      role  = "responder"
    },

  ]

  users_de_g7_dev = [
    {
      name  = "Matt Heery"
      email = "matt.heery@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Lalitha Nagarur"
      email = "lalitha.nagarur3@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Matt Price"
      email = "matthew.price2@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Andrew Craik"
      email = "andrew.craik@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Supratik Chowdhury"
      email = "supratik.chowdhury@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Tapan Perkins"
      email = "tapan.perkins@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Thomas Hepworth"
      email = "thomas.hepworth@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Philip Sinfield"
      email = "philip.sinfield@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Laurence Droy"
      email = "laurence.droy@justice.gov.uk"
      role  = "responder"
    },

  ]
}

module "schedules_de_dev" {
  for_each = { for schedule in local.schedules_de_loc_dev : schedule.name => schedule }

  source = "./modules/schedule"
  name   = each.key
  team   = each.value.team
  layers = each.value.layers

  depends_on = [module.teams_de_dev]
}

module "teams_de_dev" {
  for_each = local.teams_de_dev

  source     = "./modules/team"
  name       = each.key
  responders = each.value.responders
  depends_on = [module.users_de_seo_dev, module.users_de_g7_dev]
}

module "users_de_seo_dev" {
  for_each = { for user in local.users_de_seo_dev : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.key
}

module "users_de_g7_dev" {
  for_each = { for user in local.users_de_g7_dev : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.key
}

import {
  to = module.users_de_seo_dev["guy.wheeler@justice.gov.uk"].pagerduty_user.this
  id = "PWL9H7T"
}

import {
  to = module.users_de_g7_dev["matt.heery@justice.gov.uk"].pagerduty_user.this
  id = "PKCT98I"
}

import {
  to = module.users_de_g7_dev["lalitha.nagarur3@justice.gov.uk"].pagerduty_user.this
  id = "PKIIO6K"
}

import {
  to = module.users_de_g7_dev["matthew.price2@justice.gov.uk"].pagerduty_user.this
  id = "PW0GM04"
}

import {
  to = module.users_de_seo_dev["siva.bathina@digital.justice.gov.uk"].pagerduty_user.this
  id = "POQ8MD1"
}

import {
  to = module.users_de_seo_dev["murad.ali@justice.gov.uk"].pagerduty_user.this
  id = "PFFFZBU"
}

import {
  to = module.users_de_seo_dev["andrew.cook@digital.justice.gov.uk"].pagerduty_user.this
  id = "PZDNZKP"
}

import {
  to = module.users_de_seo_dev["anthony.cody@digital.justice.gov.uk"].pagerduty_user.this
  id = "PIUFXQZ"
}

import {
  to = module.users_de_seo_dev["thomas.hirsch@justice.gov.uk"].pagerduty_user.this
  id = "PWPVBYR"
}

import {
  to = module.users_de_seo_dev["william.orr@digital.justice.gov.uk"].pagerduty_user.this
  id = "P5XVEI1"
}

import {
  to = module.users_de_g7_dev["andrew.craik@justice.gov.uk"].pagerduty_user.this
  id = "PBLDKJP"
}

import {
  to = module.users_de_g7_dev["supratik.chowdhury@digital.justice.gov.uk"].pagerduty_user.this
  id = "PUZN13S"
}

import {
  to = module.users_de_g7_dev["thomas.hepworth@justice.gov.uk"].pagerduty_user.this
  id = "PINRNK0"
}

import {
  to = module.users_de_g7_dev["tapan.perkins@digital.justice.gov.uk"].pagerduty_user.this
  id = "PXAKE4K"
}

import {
  to = module.users_de_g7_dev["laurence.droy@justice.gov.uk"].pagerduty_user.this
  id = "P2SZG76"
}

import {
  to = module.users_de_g7_dev["philip.sinfield@justice.gov.uk"].pagerduty_user.this
  id = "P94ZLYO"
}

import {
  to = module.users_de_seo_dev["khristiania.raihan@justice.gov.uk"].pagerduty_user.this
  id = "P0O354I"
}

import {
  to = module.users_de_seo_dev["mohammed.ahad1@justice.gov.uk"].pagerduty_user.this
  id = "P1USSNR"
}
