module "data_engineering_probation_glue_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.0"


  name            = "data-engineering-probation-glue"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::189157455002:role/oasys-dev-metadata-generator",
          "arn:aws:iam::189157455002:role/oasys-preprod-metadata-generator",
          "arn:aws:iam::189157455002:role/oasys-prod-metadata-generator",
          "arn:aws:iam::189157455002:role/delius-preprod-metadata-generator",
          "arn:aws:iam::189157455002:role/delius-prod-metadata-generator"
        ]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    glue_access = {
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
  }
}
