locals {
  # absolute path to the folder the user passes in
  tags_path   = abspath("${path.root}/../data_hub_accounts/${var.data_hub_account_path}")
  config_file = "${local.tags_path}/config.yaml"

  # decode the YAML into a map
  config = yamldecode(file(local.config_file))

  # pull out the "users" block (your lf‐tag definitions)
  lf_tags = lookup(local.config, "users", {})

  user_policies = {
    for user, attrs in local.lf_tags : user => {
      lf_tag_policy = attrs.lf_tag_policy
    }
  }

}

output "hub_lf_tags" {
  description = "All lf_tags mapping for the development account"
  value       = local.lf_tags
}
