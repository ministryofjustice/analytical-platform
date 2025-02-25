##################################################
# Airflow SQLite
##################################################

resource "auth0_client" "airflow_sqlite" {
  name                = "Airflow EKS"
  description         = "Auth0 Client used by Airflow on EKS"
  app_type            = "regular_web"
  callbacks           = ["https://*-airflow-sqlite.tools.${var.route53_zone}/callback"]
  allowed_logout_urls = ["https://*-airflow-sqlite.tools.${var.route53_zone}"]
  oidc_conformant     = true
  cross_origin_auth   = true
  jwt_configuration {
    alg = "RS256"
  }
}

##################################################
# RStudio
##################################################

resource "auth0_client" "rstudio" {
  name                = "RStudio EKS"
  description         = "Auth0 Client used by RStudio on EKS"
  app_type            = "regular_web"
  callbacks           = ["https://*-rstudio.tools.${var.route53_zone}/callback"]
  allowed_logout_urls = ["https://*-rstudio.tools.${var.route53_zone}"]
  oidc_conformant     = true
  cross_origin_auth   = true
  jwt_configuration {
    alg = "HS256"
  }
}

##################################################
# Jupyter Lab
##################################################

resource "auth0_client" "jupyter_lab" {
  name        = "Jupyter Lab EKS"
  description = "Auth0 Client used by Jupyter Lab on EKS"
  app_type    = "regular_web"
  callbacks = [
    "https://*-jupyter-lab.tools.${var.route53_zone}/callback",
    "https://*-jupyter-lab-tunnel.tools.analytical-platform.service.justice.gov.uk/callback"
  ]
  allowed_logout_urls = [
    "https://*-jupyter-lab.tools.${var.route53_zone}",
    "https://*-jupyter-lab-tunnel.tools.${var.route53_zone}"
  ]
  oidc_conformant   = true
  cross_origin_auth = true
  jwt_configuration {
    alg = "HS256"
  }
}

##################################################
# Control Panel
##################################################

resource "auth0_client" "controlpanel" {
  name                = "Control Panel EKS"
  description         = "Auth0 Client used by Control Panel on EKS"
  app_type            = "regular_web"
  callbacks           = ["https://controlpanel.services.${var.route53_zone}/oidc/callback/"]
  allowed_logout_urls = ["https://controlpanel.services.${var.route53_zone}"]
  oidc_conformant     = true
  cross_origin_auth   = true
  jwt_configuration {
    alg = "RS256"
  }
}

