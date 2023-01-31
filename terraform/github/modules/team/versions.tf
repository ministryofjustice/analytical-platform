terraform {
  required_version = "~> 1.0"
  required_providers {
    github = {
      version = "~> 5.2"
      source  = "integrations/github"
      configuration_aliases = [
        github.repositories, github.teams
      ]

    }
  }
}