module "data_catalogue_team" {
  source = "./modules/team"

  name        = "data-catalogue"
  description = "Data Catalogue Team"
  members = [
    "alex-vonfeldmann", # Alex Von Feldmann
    "jemnery",          # Jeremy Collins
    "LavMatt",          # Matt Laverty
    "MatMoore",         # Mat Moore
    "mitchdawson1982",  # Mitch Dawson
    "murdo-moj",        # Murdo Moyse
    "seanprivett",      # Sean Privett
    "Tod-Christov",     # Todor Christov
    "tom-webber",       # Tom Webber
    "YvanMOJdigital",   # Yvan Smith
  ]
}

module "data_catalogue_repository" {
  source = "./modules/repository"

  name        = "data-catalogue"
  description = "Data catalogue"
  topics      = ["data-catalogue"]

  use_template = true
  has_projects = "true"
  homepage_url = null

  access = {
    admins = [module.data_catalogue_team.id]
  }
}

module "find_moj_data_repository" {
  source = "./modules/repository"

  name        = "find-moj-data"
  description = "Find MOJ data service"
  topics      = ["data-catalogue"]

  use_template        = true
  template_repository = "data-platform-app-template"
  has_projects        = "true"
  homepage_url        = null

  access = {
    admins = [module.data_catalogue_team.id]
  }
}

module "datahub_custom_api_source_repository" {
  source = "./modules/repository"

  name        = "datahub-custom-api-source"
  description = "Custom ingestion source for Datahub to consume from https://data.justice.gov.uk/api"
  topics      = ["data-catalogue"]

  use_template = true
  has_projects = "true"
  homepage_url = null

  access = {
    admins = [module.data_catalogue_team.id]
  }
}

module "data_catalogue_metadata_repository" {
  source = "./modules/repository"

  name        = "data-catalogue-metadata"
  description = "Data Catalogue Metadata"
  topics      = ["data-catalogue"]
  visibility  = "internal"

  use_template = false
  has_projects = "true"
  homepage_url = null

  advanced_security_status               = "disabled"
  secret_scanning_status                 = "disabled"
  secret_scanning_push_protection_status = "disabled"

  access = {
    admins = [module.data_catalogue_team.id]
  }
}

module "datahub_custom_domain_source_repository" {
  source = "./modules/repository"

  name        = "datahub-custom-domain-source"
  description = "Custom ingestion source for Datahub to get domains as set in the create-a-derived-table service"
  topics      = ["data-catalogue"]

  use_template = true
  has_projects = "true"
  homepage_url = null

  access = {
    admins = [module.data_catalogue_team.id]
  }
}

module "data_catalogue_runbooks_repository" {
  source = "./modules/repository"

  name        = "data-catalogue-runbooks"
  description = "Data Catalogue Runbooks"
  topics      = ["ministryofjustice", "data-platform", "data-catalogue"]

  has_issues   = true
  homepage_url = "https://runbooks.data-catalogue.service.justice.gov.uk"

  template_repository = "template-documentation-site"

  pages_enabled = true
  pages_configuration = {
    cname = "runbooks.data-catalogue.service.justice.gov.uk"
    source = {
      branch = "main"
      path   = "/"
    }
  }
  access = {
    admins  = [module.data_catalogue_team.id]
    pushers = [module.data_platform_team.id]
  }
}

module "data_catalogue_user_guide_repository" {
  source = "./modules/repository"

  name        = "data-catalogue-user-guide"
  description = "Data Catalogue User guide"
  topics      = ["ministryofjustice", "data-platform", "data-catalogue"]

  has_issues   = true
  homepage_url = "https://user-guide.data-catalogue.service.justice.gov.uk"

  template_repository = "template-documentation-site"

  pages_enabled = true
  pages_configuration = {
    cname = "user-guide.data-catalogue.service.justice.gov.uk"
    source = {
      branch = "main"
      path   = "/"
    }
  }
  access = {
    admins  = [module.data_catalogue_team.id]
    pushers = [module.data_platform_team.id]
  }
}
