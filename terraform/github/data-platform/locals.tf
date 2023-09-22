locals {
  core_repos = [{ # Legacy Analytical Platform Internal Infrastructure Repos in the MOJ org
      name        = "analytics-platform-infrastructure",
      description = "Core Infrastructure Repo for Data Platform"
    },
    {
      name        = "ap-test-github-workflow",
      description = "Test repository for github docker workflow"
  }]

  data_platform_repos = [{ # Repos to Support the Buildout of the Data Platform
    name        = "data-platform",
    description = "Core Repo for Data Platform"
    },
    {
      name        = "data-platform-products",
      description = "Core Repository for Data Platform Data Products"
    },
    {
      name        = "data-platform-support",
      description = "Core Repository for Data Platform Support"
    }
  ]

  # All Tech Archs
  tech_archs = concat(local.tech_archs_members, local.tech_archs_maintainers)

  # All Data Engineers
  all_members_data_engineers = concat(
    local.data_engineering_maintainers,
    local.data_engineering_members,
    local.data_engineering_aws_members
  )

  all_members_data_platform_core_infrastructure = concat(
    local.data_platform_core_infrastructure_maintainers,
    local.data_platform_core_infrastructure_members
  )

  all_members_data_platform_labs = concat(
    local.data_platform_labs_maintainers,
    local.data_platform_labs_members
  )

  # All members
  all_members = concat(local.general_members, local.engineers)
}
