resource "pagerduty_team" "this" {
  name = var.name
}

resource "pagerduty_team_membership" "managers" {
  for_each = var.managers

  team_id = pagerduty_team.this.id
  user_id = each.key
  role    = "manager"
}

resource "pagerduty_team_membership" "responders" {
  for_each = var.responders

  team_id = pagerduty_team.this.id
  user_id = each.key
  role    = "responder"
}
