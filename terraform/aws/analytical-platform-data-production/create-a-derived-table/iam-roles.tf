module "create_a_derived_table_iam_role" {
  #checkov:skip=CKV_AWS_358:This appears to be a false positive, we are specifying the organisation name

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=62b8a16c73d8e4422cd81923e46948e8f4b5cf48" # v3.2.0

  role_name            = "create-a-derived-table"
  github_repositories  = ["moj-analytical-services/create-a-derived-table"]
  policy_arns          = [module.create_a_derived_table_iam_policy.arn]
  max_session_duration = 10800

  tags = var.tags
}
