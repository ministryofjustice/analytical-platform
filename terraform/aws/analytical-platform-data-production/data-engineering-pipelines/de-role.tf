module "data_engineering_probation_glue_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.58.0"

  create_role = true

  role_name         = "data-engineering-probation-glue"
  role_requires_mfa = false

  trusted_role_arns = ["arn:aws:iam::189157455002:role/oasys-dev-metadata-generator","arn:aws:iam::189157455002:role/oasys-preprod-metadata-generator"]

  inline_policy_statements = [
    {
      sid    = "GlueAccess"
      effect = "Allow"
      actions = [
        "glue:GetTable",
        "glue:GetDatabase",
        "glue:GetCatalog",
        "glue:UpdateTable",
        "glue:UpdatePartition",
        "glue:UpdateDatabase",
        "glue:DeleteTableVersion",
        "glue:DeleteTable",
        "glue:DeletePartition",
        "glue:DeleteDatabase",
        "glue:CreateTable",
        "glue:CreatePartition",
        "glue:CreateDatabase",
        "glue:BatchDeleteTableVersion",
        "glue:BatchDeleteTable",
        "glue:BatchDeletePartition",
        "glue:BatchCreatePartition"
      ]
      resources = [
        "arn:aws:glue:eu-west-1:593291632749:table/oasys*/*",
        "arn:aws:glue:eu-west-1:593291632749:database/oasys*",
        "arn:aws:glue:eu-west-1:593291632749:table/delius*/*",
        "arn:aws:glue:eu-west-1:593291632749:database/delius*",
        "arn:aws:glue:eu-west-1:593291632749:catalog"
      ]
    }
  ]

}
