locals {
  # Monday to Friday, 09:00 for 8 hours
  weekday_restrictions_ae = [
    for day in range(1, 6) : {
      type              = "weekly_restriction"
      start_day_of_week = day
      start_time_of_day = "09:00:00"
      duration_seconds  = 28800
    }
  ]

  schedules_ae_loc = [
    {
      name = "Analytics Engineering Support SEO_HEO"
      team = module.teams_ae["Analytics Engineering Support SEO_HEO"].id
      layers = [
        {
          name                         = "AE Daily Support Rota SEO_HEO"
          start                        = "2023-03-27T09:00:00Z"
          rotation_virtual_start       = "2026-10-26T00:00:00+00:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users_ae_seo["brian.seery@justice.gov.uk"].id,
            module.users_ae_seo["vijay.solanki@justice.gov.uk"].id,
            module.users_ae_seo["billy.pawsey@justice.gov.uk"].id,
            module.users_ae_seo["clare.plater@justice.gov.uk"].id,
            module.users_ae_seo["rebeccaanne.ratcliffe@justice.gov.uk"].id,
            module.users_ae_seo["owen.buckley@justice.gov.uk"].id,
            module.users_ae_seo["rebecca.jukes@justice.gov.uk"].id
          ]
          restrictions = local.weekday_restrictions_ae
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
          rotation_virtual_start       = "2026-10-26T00:00:00+00:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users_ae_g7["keeleyann.kerr@justice.gov.uk"].id,
            module.users_ae_g7["eliza.carey@justice.gov.uk"].id,
            module.users_ae_g7["matthew.rixson@justice.gov.uk"].id,
            module.users_ae_g7["ivy.lau1@justice.gov.uk"].id,
            module.users_ae_g7["ian.rickard@justice.gov.uk"].id,
            module.users_ae_g7["ben.waterfield1@justice.gov.uk"].id,
            module.users_ae_g7["quinta.davies@justice.gov.uk"].id,
            module.users_ae_g7["danielle.kelly1@justice.gov.uk"].id,
            module.users_ae_g7["alex.pavlopoulos@justice.gov.uk"].id,
            module.users_ae_g7["neil.wilkins@justice.gov.uk"].id
          ]
          restrictions = local.weekday_restrictions_ae
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
    }
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
      name  = "Billy Pawsey"
      email = "billy.pawsey@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Vijay Solanki"
      email = "vijay.solanki@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Brian Seery"
      email = "brian.seery@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Clare Plater"
      email = "clare.plater@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Rebecca Anne Ratcliffe"
      email = "rebeccaanne.ratcliffe@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Rebecca Jukes"
      email = "rebecca.jukes@justice.gov.uk"
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
    },
    {
      name  = "Ivy Lau"
      email = "ivy.lau1@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Ian Rickard"
      email = "ian.rickard@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Ben Waterfield"
      email = "ben.waterfield1@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Quin Davies"
      email = "quinta.davies@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Danielle Kelly"
      email = "danielle.kelly1@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Matthew Rixson"
      email = "matthew.rixson@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Neil Wilkins"
      email = "neil.wilkins@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Keeley Ann Kerr"
      email = "keeleyann.kerr@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Eliza Carey"
      email = "eliza.carey@justice.gov.uk"
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

# SEO_HEO

import {
  to = module.users_ae_seo["owen.buckley@justice.gov.uk"].pagerduty_user.this
  id = "PRTC0Q5"
}

import {
  to = module.users_ae_seo["vijay.solanki@justice.gov.uk"].pagerduty_user.this
  id = "PUG9B4N"
}

import {
  to = module.users_ae_seo["billy.pawsey@justice.gov.uk"].pagerduty_user.this
  id = "P5Q9MQL"
}

import {
  to = module.users_ae_seo["brian.seery@justice.gov.uk"].pagerduty_user.this
  id = "P32SEQW"
}

import {
  to = module.users_ae_seo["rebeccaanne.ratcliffe@justice.gov.uk"].pagerduty_user.this
  id = "P4ZYZ3K"
}

import {
  to = module.users_ae_seo["clare.plater@justice.gov.uk"].pagerduty_user.this
  id = "P10NYRX"
}

import {
  to = module.users_ae_seo["rebecca.jukes@justice.gov.uk"].pagerduty_user.this
  id = "POZQIOR"
}

# G7

import {
  to = module.users_ae_g7["alex.pavlopoulos@justice.gov.uk"].pagerduty_user.this
  id = "PEMXSEN"
}

import {
  to = module.users_ae_g7["holly.furniss@justice.gov.uk"].pagerduty_user.this
  id = "PLVNCOV"
}

import {
  to = module.users_ae_g7["ivy.lau1@justice.gov.uk"].pagerduty_user.this
  id = "PSL3YUP"
}

import {
  to = module.users_ae_g7["ian.rickard@justice.gov.uk"].pagerduty_user.this
  id = "PSYN8E2"
}

import {
  to = module.users_ae_g7["ben.waterfield1@justice.gov.uk"].pagerduty_user.this
  id = "P3VR0H2"
}

import {
  to = module.users_ae_g7["quinta.davies@justice.gov.uk"].pagerduty_user.this
  id = "P5D5U7A"
}

import {
  to = module.users_ae_g7["danielle.kelly1@justice.gov.uk"].pagerduty_user.this
  id = "PYZL4R9"
}

import {
  to = module.users_ae_g7["matthew.rixson@justice.gov.uk"].pagerduty_user.this
  id = "PREPU2L"
}

import {
  to = module.users_ae_g7["neil.wilkins@justice.gov.uk"].pagerduty_user.this
  id = "PEASOWW"
}

import {
  to = module.users_ae_g7["keeleyann.kerr@justice.gov.uk"].pagerduty_user.this
  id = "PKY1EDG"
}

import {
  to = module.users_ae_g7["eliza.carey@justice.gov.uk"].pagerduty_user.this
  id = "PP6NNQ1"
}
