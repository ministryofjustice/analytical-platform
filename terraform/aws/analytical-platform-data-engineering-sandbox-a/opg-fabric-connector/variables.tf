variable "default_tenant_value" {
  type      = string
  sensitive = true
  default   = "CHANGEME"
}

variable "default_object_value" {
  type      = string
  sensitive = true
  default   = "CHANGEME"
}


variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}
