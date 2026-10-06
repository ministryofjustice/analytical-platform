variable "name" {
  type        = string
  description = "Name of the team"
}

variable "members" {
  type = map(object({
    name = string
    id   = string
    role = string
  }))

  description = "Members to add to the team"

  validation {
    condition = alltrue([
      for member in values(var.members) :
      contains(["manager", "responder"], member.role)
    ])

    error_message = "Team member role must be manager or responder."
  }
}
