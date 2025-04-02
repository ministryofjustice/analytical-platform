locals {
  schedules_de_loc = [
    {
      name = "Data Engineering Support SEO"
      team = module.teams_de["Data Engineering Support SEO"].id
      layers = [
        {
          name                         = "DE Daily Support Rota SEO"
          start                        = "2023-03-27T09:00:00Z"
          rotation_virtual_start       = "2024-09-20T09:00:00+01:00"
          rotation_turn_length_seconds = 86400
          users = [
            module.users_de_seo["guy.wheeler@justice.gov.uk"].id,
            module.users_de_seo["thomas.hepworth@justice.gov.uk"].id,
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
            module.users_de_g7["lalitha.nagarur3@justice.gov.uk"].id,
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

module "schedules_de" {
  for_each = { for schedule in local.schedules_de_loc : schedule.name => schedule }

  source = "./modules/schedule"
  name   = each.key
  team   = each.value.team
  layers = each.value.layers

  depends_on = [module.teams_de]
}

locals {
  teams_de = {
    "Data Engineering Support SEO" = {
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
}

module "teams_de" {
  for_each = local.teams_de

  source     = "./modules/team"
  name       = each.key
  responders = each.value.responders
  depends_on = [module.users_de_seo, module.users_de_g7]
}

locals {
  users_de_seo = [
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

module "users_de_seo" {
  for_each = { for user in local.users_de_seo : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.key
}

locals {
  users_de_g7 = [
    {
      name  = "Matt Heery"
      email = "matt.heery@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Lalitha Nagarur"
      email = "lalitha.nagarur3@justice.gov.uk"
      role  = "responder"
    }
  ]
}

module "users_de_g7" {
  for_each = { for user in local.users_de_g7 : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.key
}
