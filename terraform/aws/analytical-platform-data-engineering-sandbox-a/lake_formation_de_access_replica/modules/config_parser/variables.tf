variable "config_dir" {
  description = "Path to directory containing YAML files where the LakeFormation config is defined"
  type        = string
}

variable "projects_path" {
  description = "Path to directory containing project YAML files"
  type        = string
  default     = "projects"
}
