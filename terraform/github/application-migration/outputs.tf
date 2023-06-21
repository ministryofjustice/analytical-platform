output "team_list" {
  value = transpose(local.team_repo_map)
}

