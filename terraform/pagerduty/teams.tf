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

moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.managers["PKTVSPE"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.managers["jacob.woffenden@digital.justice.gov.uk"]
}
moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.managers["PYO8C08"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.managers["julia.lawrence@digital.justice.gov.uk"]
}
moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.managers["PJTSCUW"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.managers["richard.baguley@digital.justice.gov.uk"]
}
moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.managers["PWEB0DB"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.managers["yvan.smith@digital.justice.gov.uk"]
}


moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.responders["PDYN5MO"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.responders["emma.terry@digital.justice.gov.uk"]
}
moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.responders["PBXQQO8"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.responders["brian.ellwood@digital.justice.gov.uk"]
}
moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.responders["PYCWEKM"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.responders["michael.collins@digital.justice.gov.uk"]
}
moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.responders["PBS7XJH"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.responders["gary.henderson@digital.justice.gov.uk"]
}
moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.responders["PPZTQR5"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.responders["jacob.hamblin-pyke@digital.justice.gov.uk"]
}
moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.responders["PA77LTD"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.responders["james.stott@digital.justice.gov.uk"]
}
moved {
  from = module.teams["Analytical Platform"].pagerduty_team_membership.responders["PYN3HDP"]
  to   = module.teams["Analytical Platform"].pagerduty_team_membership.responders["anthony.fitzroy@digital.justice.gov.uk"]
}
