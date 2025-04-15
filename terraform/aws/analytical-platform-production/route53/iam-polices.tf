#trivy:ignore:avd-aws-0057:Wildcard is suggested from listing zones
data "aws_iam_policy_document" "analytical_platform_compute_route53_access" {
  #checkov:skip=CKV_AWS_356:Wildcard is suggested from listing zones

  statement {
    sid    = "AllowRoute53List"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowRoute53ChangeResourceRecordSets"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [module.route53_zones.route53_zone_zone_arn["analytical-platform.service.justice.gov.uk"]]
  }
}

module "analytical_platform_compute_route53_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.55.0"

  name_prefix = "analytical-platform-compute-route53-access"

  policy = data.aws_iam_policy_document.analytical_platform_compute_route53_access.json
}
