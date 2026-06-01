locals {
  # 1) Find all YAML files
  yaml_files = fileset(var.config_dir, "*.y*ml")

  # 2) Decode each file, defaulting to {} on parse error
  yaml_contents = {
    for f in local.yaml_files :
    f => try(yamldecode(file("${var.config_dir}/${f}")), {})
  }

  # 3) Find all YAML files in projects directory
  projects_yaml_files = fileset("${var.config_dir}/projects", "*.y*ml")

  # 4) Decode projects files with filename (without extension) as key
  projects = {
    for f in local.projects_yaml_files :
    trimsuffix(trimsuffix(f, ".yaml"), ".yml") => try(yamldecode(file("${var.config_dir}/projects/${f}")), {})
  }
}
