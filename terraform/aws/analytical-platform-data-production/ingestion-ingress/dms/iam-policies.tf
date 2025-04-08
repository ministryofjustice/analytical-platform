data "aws_iam_policy_document" "dms_ingress_iam_policy" {
  statement {
    sid    = "AllowDMSGlueAccess"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:GetDatabase",
      "glue:CreateDatabase"
    ]
    resources = [
      "arn:aws:glue:eu-west-2:${var.account_ids["analytical-platform-data-production"]}:catalog",
      "arn:aws:glue:eu-west-2:${var.account_ids["analytical-platform-data-production"]}:database/cica_tariff",
      "arn:aws:glue:eu-west-2:${var.account_ids["analytical-platform-data-production"]}:table/cica_tariff/*"
    ]
  }
}

module "dms_ingress_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.analytical_platform_ingestion_environments

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.1"

  name_prefix = "mojap-data-production-dms-ingress-${each.key}"

  policy = data.aws_iam_policy_document.dms_ingress_iam_policy.json
}
