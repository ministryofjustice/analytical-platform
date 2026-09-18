variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}

variable "namespace" {
  type = string
}

variable "org_member_reader_github_token" {
  type        = string
  description = "Short-lived token from the Octo STS org-member-reader identity (.github/chainguard/org-member-reader.sts.yaml), used only for the github provider"
  sensitive   = true
}
