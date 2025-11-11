locals {
  datahub_cp_irsa_role_arns = {
    for env, role_name in var.datahub_cp_irsa_role_names :
    env => "arn:aws:iam::${var.account_ids["cloud-platform"]}:role/${role_name}"
  }

  ingest_athena_nons3 = [
    "arn:aws:athena::${var.account_ids["analytical-platform-data-production"]}:datacatalog/*",
    "arn:aws:athena::${var.account_ids["analytical-platform-data-production"]}:workgroup/*",
    "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:tableVersion/*/*/*",
    "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:table/*/*",
    "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:catalog",
    "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:database/*"
  ]

  ingest_athena_s3 = concat(
    formatlist("arn:aws:s3:::%s/*", var.data_buckets),
    formatlist("arn:aws:s3:::%s", var.data_buckets)
  )

  transcribe_users = [
    "alpha_user_rogerbrownmoj",
    "alpha_user_laura-auburn",
    "alpha_user_rob-mcnaughter"
  ]

}
