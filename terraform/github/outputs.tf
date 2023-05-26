output "team_list" {
  value = {
    for repo, details in data.github_repository_teams.migration_apps_repo_owners :
    repo => [for team in details.teams : team.name]
  }
}
