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
        module.users[user.email].id => {
          name = user.name
          id   = module.users[user.email].id
          email = user.email
        }
        if user.role == "responder"
      }
}
  }
}


# module "teams" {
#   for_each = local.users

#   source     = "./modules/team"
#   name       = each.value.name
#   managers   =  {
#     for email, user in local.users :
#     email => {
#       name = user.name
#       id   = module.users[email].id
#     }
#     if user.role == "manager"
#   }
#   responders = {
#     for email, user in local.users :
#     email => {
#       name = user.name
#       id   = module.users[email].id
#     }
#     if user.role == "responder"
#   }
module "teams" {
  for_each = local.teams

  source     = "./modules/team"
  name       = each.key
  managers   = each.value.managers
  responders = each.value.responders
  depends_on = [module.users]
}


# I thin