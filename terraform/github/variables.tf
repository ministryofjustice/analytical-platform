variable "team_github_token" {
  description = "GitHub token for Team Management"
  type        = string
  sensitive   = true
}

variable "repository_github_token" {
  description = "GitHub token for Repository Management"
  type        = string
  sensitive   = true
}