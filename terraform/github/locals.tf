locals {
  core_repos = [{ # Legacy Analytical Platform Internal Infrastructure Repos in the MOJ org
    name        = "ap-terraform-bootstrap",
    description = "Bootstrap for setting up analytical platform and data engineering accounts"
    },
    {
      name        = "analytics-platform-infrastructure",
      description = "Core Infrastructure Repo for Data Platform"
    },
    {
      name        = "ap-test-github-workflow",
      description = "Test repository for github docker workflow"
  }]
  # All Tech Archs
  tech_archs = concat(local.tech_archs_members, local.tech_archs_maintainers)
  # All data engineers

  all_members_data_engineers = concat(local.data_engineering_maintainers, local.data_engineering_members)

  # All members
  all_members = concat(local.general_members, local.engineers)

  # Everyone
  everyone = concat(local.all_maintainers, local.all_members)
}
