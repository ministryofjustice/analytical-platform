locals {
  datahub_cp_irsa_role_arns = flatten(
    [
      for env, role_name in var.datahub_cp_irsa_role_names :
      { (env) = "arn:aws:iam::${var.account_ids["cloud-platform"]}:role/${role_name}" }
    ]
  )
}
