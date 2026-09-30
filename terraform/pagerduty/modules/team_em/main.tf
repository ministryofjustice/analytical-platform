resource "pagerduty_team" "this" {
  name = var.name
}

resource "pagerduty_team_membership" "members" {
  for_each = var.members

  team_id = pagerduty_team.this.id
  user_id = each.value.id
  role    = each.value.role
}

moved {
  from = pagerduty_team_membership.responders
  to   = pagerduty_team_membership.members
}
