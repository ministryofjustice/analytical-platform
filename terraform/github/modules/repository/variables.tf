variable "name" {
  type        = string
  description = "Repository name"
}

variable "description" {
  type        = string
  description = "Repository description"
}

variable "homepage_url" {
  type        = string
  description = "Repository homepage URL"
  default     = ""
}

variable "secrets" {
  type        = map(any)
  description = "key:value map for GitHub actions secrets"
  default     = {}
}

variable "topics" {
  type        = list(string)
  description = "Repository topics, in addition to 'data-platform', 'terraform-module', 'civil-service'"
}

variable "type" {
  type        = string
  description = "Type of repository: `core`, `module`, `template`, `app`. Defaults to `core`"
  default     = "core"
}

variable "visibility" {
  type        = string
  description = "Visibility type: `public`, `internal`, `private`"
  default     = "public"
}

variable "required_checks" {
  type        = list(string)
  description = "List of required checks"
  default     = []
}

variable "require_signed_commits" {
  description = "Require signed commits on the repository"
  type        = bool
  default     = false

}

variable "environments" {
  description = "Set of environment names"
  type        = set(string)
  default     = []
}
