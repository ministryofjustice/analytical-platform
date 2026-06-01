data "aws_caller_identity" "current" {}

resource "aws_lakeformation_permissions" "user_policies" {
  for_each = local.user_policies
  provider = aws.source

  principal = "arn:aws:iam::593291632749:role/${each.key}"
  permissions = [
    "DESCRIBE",
    "SELECT",
  ]

  lf_tag_policy {
    resource_type = "TABLE"

    dynamic "expression" {
      for_each = each.value.lf_tag_policy[0]
      content {
        key    = expression.key
        values = expression.value
      }
    }
  }
}
