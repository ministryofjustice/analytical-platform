variable "name" {
  type        = string
  description = "Name of the escalation policy"
}

variable "description" {
  type        = string
  description = "Description of the escalation policy"
}

variable "team" {
  type        = string
  description = "ID of the team to assign to this escalation policy"
}

variable "num_loops" {
  type        = number
  description = "Number of times to loop through the escalation targets"
}

variable "rules" {
  type = list(object({
    escalation_delay_in_minutes = number,
    targets = list(object({
      type = string,
      id   = string
    }))
  }))
  description = "List of rules to escalate to"
}
