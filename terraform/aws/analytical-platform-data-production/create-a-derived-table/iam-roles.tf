module "create_a_derived_table_iam_role" {
  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=9d9a2d23cf569348cbdb665c979fcbaed76bb2f4" # v3.1.0

  role_name           = "create-a-derived-table"
  github_repositories = ["moj-analytical-services/create-a-derived-table"]
  policy_arns         = [module.create_a_derived_table_iam_policy.arn]

  tags = var.tags
}
