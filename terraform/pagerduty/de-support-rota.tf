locals {
  schedules_de_loc = [
    {
      name = "Data Engineering Support HEO_SEO"
      team = module.teams_de["Data Engineering Support HEO_SEO"].id
      layers = [
        {
          name                         = "DE Daily Support Rota HEO_SEO"
          start                        = "2023-03-27T09:00:00Z"
          rotation_virtual_start       = "2024-09-20T09:00:00+01:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users_de_seo["guy.wheeler@justice.gov.uk"].id,
            module.users_de_seo["siva.bathina@digital.justice.gov.uk"].id,
            module.users_de_seo["murad.ali@justice.gov.uk"].id,
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
      name = "Data Engineering Support G7"
      team = module.teams_de["Data Engineering Support G7"].id
      layers = [
        {
          name                         = "DE Daily Support Rota G7"
          start                        = "2023-03-27T09:00:00Z"
          rotation_virtual_start       = "2024-09-20T09:00:00+01:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users_de_g7["matt.heery@justice.gov.uk"].id,
            module.users_de_g7["lalitha.nagarur@digital.justice.gov.uk"].id,
            module.users_de_g7["thomas.hepworth@justice.gov.uk"].id,
            module.users_de_g7["matthew.price2@justice.gov.uk"].id,
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

  teams_de = {
    "Data Engineering Support HEO_SEO" = {
      responders = {
        for user in local.users_de_seo :
        user.email => {
          name = user.name
          id   = module.users_de_seo[user.email].id
        }
        if user.role == "responder"
      }
    },
    "Data Engineering Support G7" = {
      responders = {
        for user in local.users_de_g7 :
        user.email => {
          name = user.name
          id   = module.users_de_g7[user.email].id
        }
        if user.role == "responder"
      }
    }
  }

  users_de_seo = [
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

  ]

  users_de_g7 = [
    {
      name  = "Matt Heery"
      email = "matt.heery@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Lalitha Nagarur"
      email = "lalitha.nagarur@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Thomas Hepworth"
      email = "thomas.hepworth@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Matt Price"
      email = "matthew.price2@justice.gov.uk"
      role  = "responder"
    }
  ]
}

module "schedules_de" {
  for_each = { for schedule in local.schedules_de_loc : schedule.name => schedule }

  source = "./modules/schedule"
  name   = each.key
  team   = each.value.team
  layers = each.value.layers

  depends_on = [module.teams_de]
}

module "teams_de" {
  for_each = local.teams_de

  source     = "./modules/team"
  name       = each.key
  responders = each.value.responders
  depends_on = [module.users_de_seo, module.users_de_g7]
}

module "users_de_seo" {
  for_each = { for user in local.users_de_seo : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.key
}

module "users_de_g7" {
  for_each = { for user in local.users_de_g7 : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.key
}

import {
  to = module.users_de_seo["guy.wheeler@justice.gov.uk"].pagerduty_user.this
  id = "PWL9H7T"
}

import {
  to = module.users_de_g7["matt.heery@justice.gov.uk"].pagerduty_user.this
  id = "PKCT98I"
}

import {
  to = module.users_de_g7["thomas.hepworth@justice.gov.uk"].pagerduty_user.this
  id = "PIAKE2C"
}

import {
  to = module.users_de_g7["lalitha.nagarur@digital.justice.gov.uk"].pagerduty_user.this
  id = "PIT5XAZ"
}

import {
  to = module.users_de_g7["matthew.price2@justice.gov.uk"].pagerduty_user.this
  id = "PW0GM04"
}

import {
  to = module.users_de_seo["siva.bathina@digital.justice.gov.uk"].pagerduty_user.this
  id = "POQ8MD1"
}

import {
  to = module.users_de_seo["murad.ali@justice.gov.uk"].pagerduty_user.this
  id = "PFFFZBU"
}
