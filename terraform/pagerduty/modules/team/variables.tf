variable "name" {
  type        = string
  description = "Name of the team"
}

variable "managers" {
    type        = map(object({
    name = string
    id = string
  }))
  description = "List of user IDs to be added as managers to the team"
  default     = {}
}

variable "responders" {
  type        = map(object({
    name = string
    id = string
  }))
  description = "List of user IDs to be added as responders to the team"
  default     = {}
}
