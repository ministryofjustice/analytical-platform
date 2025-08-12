data "aws_iam_policy_document" "bold_rr_pilot_families_nlp" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::alpha-bold-pilot-rr-families",
      "arn:aws:s3:::alpha-bold-pilot-rr-families/*"
    ]
  }
}

module "bold_rr_pilot_families_nlp_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"

  name_prefix = "github-bold-rr-pilot-families-nlp"

  policy = data.aws_iam_policy_document.bold_rr_pilot_families_nlp.json
}

module "bold_rr_pilot_families_nlp_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.60.0"

  name = "github-bold-rr-pilot-families-nlp"

  subjects = ["moj-analytical-services/bold_rr_pilot_families_nlp:*"]

  policies = {
    github_bold_rr_pilot_families_nlp = module.bold_rr_pilot_families_nlp_iam_policy.arn
  }
}
