variable "name" {
  type        = string
  description = "Name of the PagerDuty schedule"
}

variable "description" {
  type        = string
  description = "Description of the PagerDuty schedule"
}

variable "team_id" {
  type        = string
  description = "PagerDuty team ID associated with the schedule"
}

variable "time_zone" {
  type        = string
  description = "Time zone used by the schedule"
  default     = "Europe/London"
}

variable "rotations" {
  description = "Shift-based schedule rotations"

  type = list(object({
    key = string

    events = list(object({
      name              = string
      start_time        = string
      end_time          = string
      effective_since   = string
      effective_until   = optional(string)
      recurrence        = list(string)
      assignment_type   = string
      shifts_per_member = optional(number)
      member_ids        = list(string)
    }))
  }))

  validation {
    condition = alltrue(flatten([
      for rotation in var.rotations : [
        for event in rotation.events :
        contains(
          [
            "rotating_member_assignment_strategy",
            "every_member_assignment_strategy",
          ],
          event.assignment_type
        )
      ]
    ]))

    error_message = "Schedule events must use a supported assignment strategy."
  }

  validation {
    condition = alltrue(flatten([
      for rotation in var.rotations : [
        for event in rotation.events :
        length(event.member_ids) > 0
      ]
    ]))

    error_message = "Every schedule event must have at least one member."
  }

  validation {
    condition = alltrue(flatten([
      for rotation in var.rotations : [
        for event in rotation.events :
        length([
          for rule in event.recurrence :
          rule
          if startswith(rule, "RRULE:")
        ]) == 1
      ]
    ]))

    error_message = "Every schedule event must contain exactly one RRULE."
  }
}
