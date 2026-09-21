locals {
  members = merge(
    {
      for email, member in var.responders :
      email => {
        name = member.name
        id   = member.id
        role = "responder"
      }
    },
    {
      for email, member in var.managers :
      email => {
        name = member.name
        id   = member.id
        role = "manager"
      }
    }
  )
}

resource "pagerduty_team" "this" {
  name = var.name
}

resource "pagerduty_team_membership" "responders" {
  for_each = local.members

  team_id = pagerduty_team.this.id
  user_id = each.value.id
  role    = each.value.role
}