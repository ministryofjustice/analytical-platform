variable "name" {
  type        = string
  description = "Name of the team"
}

variable "managers" {
  type        = set(string)
  description = "List of user IDs to be added as managers to the team"
}

variable "responders" {
  type        = set(string)
  description = "List of user IDs to be added as responders to the team"
}
