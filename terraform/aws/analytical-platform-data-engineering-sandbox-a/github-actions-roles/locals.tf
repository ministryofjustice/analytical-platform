locals {
  eks_oidc_id  = "801920EDEF91E3CAB03E04C03A2DE2BB" # AP Compute Production
  eks_oidc_url = "https://oidc.eks.eu-west-2.amazonaws.com/id/${local.eks_oidc_id}"
  account_ids = {
    analytical-platform-data-engineering-sandbox-a = "684969100054"
    analytical-platform-management-production      = "042130406152"
    analytical-platform-compute-production         = "992382429243"
  }

  # https://technical-guidance.service.justice.gov.uk/documentation/standards/documenting-infrastructure-owners.html#documenting-owners-of-infrastructure
  tags = {
    business-unit          = "Platforms"
    application            = "Analytical Platform"
    component              = "GitHub Actions Roles"
    environment            = "sandbox"
    is-production          = "false"
    owner                  = "analytical-platform:analytical-platform@digital.justice.gov.uk"
    infrastructure-support = "analytical-platform:analytical-platform@digital.justice.gov.uk"
    source-code            = "github.com/ministryofjustice/analytical-platform/tree/main/terraform/aws/analytical-platform-data-engineering-sandbox-a/github-actions-roles"
  }
}
