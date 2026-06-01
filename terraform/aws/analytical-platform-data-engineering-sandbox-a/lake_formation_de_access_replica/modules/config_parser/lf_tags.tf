locals {
  # Extract lf_tags map or {} if absent
  lf_tags_list = [
    for c in values(local.yaml_contents) :
    try(c.lf_tags, {})
  ]

  # Extract tag_managers list or [] if absent
  tag_managers_list = [
    for c in values(local.yaml_contents) :
    try(c.tag_managers, [])
  ]

  # Flatten all tag_managers into a single list
  tag_managers = flatten(local.tag_managers_list)

  # Gather all LF tag keys
  all_tag_keys = flatten([
    for m in local.lf_tags_list : keys(m)
  ])

  # Detect duplicate tag keys (using frequency map)
  tag_key_counts = {
    for k in local.all_tag_keys :
    k => length([for x in local.all_tag_keys : x if x == k])
  }

  duplicate_tag_keys = [
    for k, v in local.tag_key_counts : k if v > 1
  ]

  # Merge lf_tags if no duplicates
  lf_tags = length(local.duplicate_tag_keys) == 0 ? merge(local.lf_tags_list...) : {}
}

# Fail early at plan/apply if duplicate lf-tags exist
resource "null_resource" "check_tag_duplicates" {
  lifecycle {
    precondition {
      condition     = length(local.duplicate_tag_keys) == 0
      error_message = "Duplicate LF-Tag keys detected: ${join(", ", local.duplicate_tag_keys)}"
    }
  }
}
