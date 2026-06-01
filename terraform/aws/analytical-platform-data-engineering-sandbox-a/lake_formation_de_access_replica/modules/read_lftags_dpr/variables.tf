variable "data_hub_account_path" {
  description = "Relative path under data_hub_accounts for this account (e.g. digital_prison_reporting/development)"
  type        = string
}


variable "bucket_name" {
  type     = string
  nullable = false
}
