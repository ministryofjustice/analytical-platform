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

module "schedules" {
  for_each = { for schedule in local.schedules : schedule.name => schedule }

  source = "./modules/schedule"
  name   = each.key
  team   = each.value.team
  layers = each.value.layers

  depends_on = [module.teams]
}
