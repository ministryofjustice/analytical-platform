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
}

resource "aws_glue_resource_policy" "ireland" {
  policy        = data.aws_iam_policy_document.glue_ireland.json
  enable_hybrid = "TRUE"
}