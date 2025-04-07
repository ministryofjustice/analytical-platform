data "aws_iam_policy_document" "dms_ingress_iam_policy" {
  statement {
    sid    = "AllowGlueAccess"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:CreateDatabase",
      "glue:UpdateDatabase"
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
