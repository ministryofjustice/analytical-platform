variable "name" {
  type        = string
  description = "Name of the business service"
}

variable "description" {
  type        = string
  description = "Description of the business service"
}

variable "point_of_contact" {
  type        = string
  description = "Point of contact for the business service"
}

variable "team" {
  type        = string
  description = "Team owner for the business service"
}

variable "supporting_services" {
  type        = list(object({ name = string, id = string, type = string }))
  description = "Business services that this business service is dependent on"
}
