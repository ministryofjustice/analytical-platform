module "mojap_compute_external_secrets_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.analytical_platform_compute_environments

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "6.0.0"

  role_name                      = "mojap-compute-${each.key}-external-secrets"
  attach_external_secrets_policy = true
  external_secrets_kms_key_arns = [
    module.secrets_manager_kms.key_arn,
    module.secrets_manager_eu_west_1_replica_kms.key_arn,
  ]
  external_secrets_secrets_manager_arns = formatlist("arn:aws:secretsmanager:%s:${var.account_ids["analytical-platform-data-production"]}:secret:/airflow/${each.key}/*", ["eu-west-2", "eu-west-1"])

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.eks_oidc[each.key].arn
      namespace_service_accounts = ["mwaa:external-secrets-analytical-platform-data-production"]
    }
  }
}
