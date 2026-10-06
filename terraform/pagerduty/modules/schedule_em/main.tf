resource "pagerduty_schedulev2" "this" {
  name        = var.name
  description = var.description
  time_zone   = var.time_zone
  teams       = [var.team_id]

  dynamic "rotation" {
    for_each = var.rotations

    content {
      dynamic "event" {
        for_each = rotation.value.events

        content {
          name            = event.value.name
          start_time      = event.value.start_time
          end_time        = event.value.end_time
          effective_since = event.value.effective_since
          effective_until = try(event.value.effective_until, null)
          recurrence      = event.value.recurrence

          assignment_strategy {
            type = event.value.assignment_type

            shifts_per_member = (
              event.value.assignment_type
              == "rotating_member_assignment_strategy"
              ? try(event.value.shifts_per_member, 1)
              : null
            )

            dynamic "member" {
              for_each = event.value.member_ids

              content {
                type    = "user_member"
                user_id = member.value
              }
            }
          }
        }
      }
    }
  }
}
