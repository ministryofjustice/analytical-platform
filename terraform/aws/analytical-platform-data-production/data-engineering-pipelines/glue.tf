data "aws_iam_policy_document" "glue_ireland" {
  policy_id = "protect-deployed-dbs"

  dynamic "statement" {
    for_each = local.protected_dbs

    content {
      sid    = statement.value.name
      effect = "Deny"
      actions = [
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
      resources = flatten([
        for pattern in statement.value.database_string_pattern : [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${pattern}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${pattern}/*"
        ]
      ])
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      condition {
        test     = "StringNotLike"
        variable = "aws:userId"
        values = flatten([
          [for user_id in statement.value.role_names_to_exempt : [
            data.aws_iam_role.glue_policy_role[user_id].unique_id,
            "${data.aws_iam_role.glue_policy_role[user_id].unique_id}:*"
          ]],
          [
            data.aws_caller_identity.current.account_id,
            data.aws_iam_role.aws_sso_modernisation_platform_data_eng.unique_id,
            "${data.aws_iam_role.aws_sso_modernisation_platform_data_eng.unique_id}:*" // data engineering role protection bypass
          ]
        ])
      }
    }
  }

  dynamic "statement" {
    for_each = local.data_engineering_dbs

    content {
      sid    = "${statement.value.name}DE"
      effect = "Allow"
      actions = [
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
        "glue:BatchCreatePartition",
        "glue:GetDatabase",
        "glue:GetTable"
      ]
      resources = flatten([
        for pattern in statement.value.database_string_pattern : [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${pattern}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${pattern}/*"
        ]
      ])
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      condition {
        test     = "StringLike"
        variable = "aws:userId"
        values = flatten(
          [for user_id in statement.value.data_engineering_role_names_to_allow : [
            data.aws_iam_role.data_engineering_glue_policy_role[user_id].unique_id,
            "${data.aws_iam_role.data_engineering_glue_policy_role[user_id].unique_id}:*"
          ]]
        )
      }
    }
  }
}

resource "aws_glue_resource_policy" "ireland" {
  policy        = data.aws_iam_policy_document.glue_ireland.json
  enable_hybrid = "TRUE"
}
