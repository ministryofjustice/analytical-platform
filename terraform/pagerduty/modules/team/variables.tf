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


# I think there are better ways to get here than explicitly defining the managers and responders as maps of objects rather than strings except I think in map of strings, the ids were still somehow were being used as a key which is why it was complaining.
# So...I wasn't entirely off-track and in similar situations, I think making sure that there's no way that an unknown value is gonna be a key in a for_each will resolve it. I did it via explicitly defining the key of the object to be something else.
