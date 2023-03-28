resource "pagerduty_schedule" "this" {
  name      = var.name
  teams     = [var.team]
  time_zone = var.time_zone

  dynamic "layer" {
    for_each = var.layers
    content {
      name                         = layer.value.name
      start                        = layer.value.start
      rotation_virtual_start       = layer.value.rotation_virtual_start
      rotation_turn_length_seconds = layer.value.rotation_turn_length_seconds
      users                        = layer.value.users
      dynamic "restriction" {
        for_each = try(layer.value.restrictions, [])
        content {
          type              = restriction.value.type
          start_time_of_day = restriction.value.start_time_of_day
          duration_seconds  = restriction.value.duration_seconds
          start_day_of_week = try(restriction.value.start_day_of_week, null)
        }
      }
    }
  }
}
