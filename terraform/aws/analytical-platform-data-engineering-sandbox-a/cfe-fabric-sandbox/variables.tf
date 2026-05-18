variable "default_tenant_value" {
  type      = string
  sensitive = true
  default   = "CHANGEME"

  validation {
    condition     = var.default_tenant_value != "CHANGEME"
    error_message = "Set default_tenant_value to a real Microsoft Entra tenant ID (GUID), not CHANGEME."
  }
}

variable "default_object_value" {
  type      = string
  sensitive = true
  default   = "CHANGEME"

  validation {
    condition     = var.default_object_value != "CHANGEME"
    error_message = "Set default_object_value to a real Microsoft Entra object ID (GUID), not CHANGEME."
  }
}


variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}
