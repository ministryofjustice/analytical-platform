variable "name" {
  type        = string
  description = "Name of the escalation policy"
}

variable "team" {
  type        = string
  description = "ID of the team to assign to this escalation policy"
}

variable "num_loops" {
  type        = number
  description = "Number of times to loop through the escalation targets"
}

variable "escalation_delay_in_minutes" {
  type        = number
  description = "Number of minutes to wait before escalating to the next target"
}

variable "targets" {
  type        = list(object({ type = string, id = string }))
  description = "List of targets to escalate to"
}
