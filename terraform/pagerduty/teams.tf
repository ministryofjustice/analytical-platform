locals {
  teams = {
    "Analytical Platform" = {
      managers = {
        for user in local.users :
        user.email => {
          name = user.name
          id   = module.users[user.email].id
        }
        if user.role == "manager"
      }
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
  managers   = each.value.managers
  responders = each.value.responders
  depends_on = [module.users]
}
