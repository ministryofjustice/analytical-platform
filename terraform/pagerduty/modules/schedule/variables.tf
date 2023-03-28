variable "name" {
  type        = string
  description = "Name of the schedule"
}

variable "team" {
  type        = string
  description = "Team owner of the schedule"
}

variable "time_zone" {
  type        = string
  description = "Time zone of the schedule"
  default     = "Europe/London"
}

variable "layers" {
  type = list(object({
    name                         = string
    start                        = string
    rotation_virtual_start       = string
    rotation_turn_length_seconds = number
    users                        = list(string)
    restrictions                 = optional(list(object({
      type              = string
      start_time_of_day = string
      duration_seconds  = number
      start_day_of_week = optional(string)
    })))
  }))
}
