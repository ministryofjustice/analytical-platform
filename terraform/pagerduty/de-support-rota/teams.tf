locals {
  teams = {
    "Data Engineering Support Team" = {
      responders = {
        for user in local.users :
        user.email => {
          name = user.name
          id   = module.users[user.email].id
        }
        if user.role == "responder"
      }
    }
  }
}

module "teams" {
  for_each = local.teams

  source     = "./modules/team"
  name       = each.key
  responders = each.value.responders
  depends_on = [module.users]
}
