locals {
  analytical_platform_compute_environments = {
    development = {
      eks_oidc_id = "1972AFFBD0701A0D1FD291E34F7D1287"
    }
    test = {
      eks_oidc_id = "9FAFCA50C4DA68A8E75FD21EA53A4F2B"
    }
    production = {
      eks_oidc_id = "801920EDEF91E3CAB03E04C03A2DE2BB"
    }
  }
}
