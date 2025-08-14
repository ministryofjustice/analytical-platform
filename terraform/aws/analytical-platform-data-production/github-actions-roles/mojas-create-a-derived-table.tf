data "aws_iam_policy_document" "create_a_derived_table" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:DeleteObject*",
      "s3:PutObject*"
    ]
    resources = [
      "arn:aws:s3:::mojap-derived-tables/*",
      "arn:aws:s3:::mojap-derived-tables",
      "arn:aws:s3:::dbt-query-dump/*",
      "arn:aws:s3:::dbt-query-dump",
      "arn:aws:s3:::mojap-manage-offences/ho-offence-codes/*",
      "arn:aws:s3:::mojap-manage-offences",
      "arn:aws:s3:::mojap-hub-exports/probation_referrals_dump/*",
      "arn:aws:s3:::mojap-hub-exports",
      "arn:aws:s3:::alpha-app-opg-lpa-dashboard",
      "arn:aws:s3:::alpha-app-opg-lpa-dashboard/dev/models/domain_name=opg/*",
      "arn:aws:s3:::alpha-app-opg-lpa-dashboard/prod/models/domain_name=opg/*",
      "arn:aws:s3:::alpha-bold-data-shares",
      "arn:aws:s3:::alpha-bold-data-shares/reducing-reoffending/*"
    ]
  }
  statement {
    sid    = "DataAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetObject*",
      "s3:GetBucket*"
    ]
    resources = [
      "arn:aws:s3:::*",
      "arn:aws:s3:::*/*"
    ]
  }
  statement {
    sid    = "readSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:/alpha/airflow/airflow_dev_cadet_deployments/cadet-deploy-key/*",
      "arn:aws:secretsmanager:*:*:secret:/alpha/airflow/airflow_dev_cadet_deployments/slack_bot_key/*"
    ]
  }
  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "athena:List*",
      "athena:Get*",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-production"]}:datacatalog/*",
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-production"]}:workgroup/*"
    ]
  }
  statement {
    sid    = "GlueAccess"
    effect = "Allow"
    actions = [
      "glue:Get*",
      "glue:DeleteTable",
      "glue:DeleteTableVersion",
      "glue:DeleteSchema",
      "glue:DeletePartition",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:UpdateSchema",
      "glue:UpdatePartition",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:CreateSchema",
      "glue:CreatePartition",
      "glue:CreatePartitionIndex",
      "glue:BatchCreatePartition",
      "glue:CreateDatabase"
    ]
    resources = [
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:schema/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:database/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:table/*/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:catalog"
    ]
  }
  statement {
    sid    = "AirflowAccess"
    effect = "Allow"
    actions = [
      "airflow:CreateCliToken"
    ]
    resources = [
      "arn:aws:airflow:*:${var.account_ids["analytical-platform-data-production"]}:environment/dev",
      "arn:aws:airflow:*:${var.account_ids["analytical-platform-data-production"]}:environment/prod"
    ]
  }
  statement {
    sid       = "AllowAssumeAPComputeMetadataTransferRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    resources = ["arn:aws:iam::${var.account_ids["analytical-platform-compute-production"]}:role/copy-apdp-cadet-metadata-to-compute"]
  }
}

module "create_a_derived_table_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.0.0"

  name_prefix = "create-a-derived-table"

  policy = data.aws_iam_policy_document.create_a_derived_table.json
}

module "create_a_derived_table_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "6.0.0"

  role_name = "create-a-derived-table"

  max_session_duration = 10800

  role_policy_arns = {
    policy = module.create_a_derived_table_iam_policy.arn
  }

  oidc_providers = {
    analytical-platform-compute-production = {
      provider_arn = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/801920EDEF91E3CAB03E04C03A2DE2BB"
      namespace_service_accounts = [
        "actions-runners:actions-runner-mojas-create-a-derived-table",
        "actions-runners:actions-runner-mojas-create-a-derived-table-non-spot"
      ]
    }
    cloud-platform = {
      provider_arn               = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/DF366E49809688A3B16EEC29707D8C09"
      namespace_service_accounts = ["data-platform-production:actions-runner-mojas-create-a-derived-table"]
    }
    data-platform-production = {
      provider_arn               = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/F147414004D7C4CF820F21F453AF80F1"
      namespace_service_accounts = ["actions-runners:actions-runner-mojas-create-a-derived-table"]
    }
  }
}
