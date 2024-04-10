#trivy:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "glue_ireland" {
  policy_id = "protect-deployed-dbs"

  dynamic "statement" {
    #checkov:skip=CKV_AWS_111: skip requires access to multiple resources
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
        variable = "aws:PrincipalArn"
        values = flatten([
          [for role_arn in statement.value.role_names_to_exempt : [
            data.aws_iam_role.glue_policy_role[role_arn].arn
          ]],
          [
            data.aws_iam_role.aws_sso_modernisation_platform_data_eng.arn,
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
