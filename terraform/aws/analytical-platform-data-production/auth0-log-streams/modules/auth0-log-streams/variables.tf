variable "name" {
  type = string
}

variable "event_source_name" {
  type = string
}

variable "retention_in_days" {
  type    = number
  default = 400
}