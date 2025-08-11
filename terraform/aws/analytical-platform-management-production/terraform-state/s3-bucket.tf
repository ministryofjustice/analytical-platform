data "aws_iam_policy_document" "state_bucket_policy" {
  // GitHub Actions via GlobalGitHubActionAdmin
  statement {
    sid       = "GitHubActionsListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.state_bucket.s3_bucket_arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"]
    }
  }
  statement {
    sid    = "GitHubActionsReadWriteBucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = ["${module.state_bucket.s3_bucket_arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"]
    }
  }
  // Analytical Platform Team
  statement {
    sid       = "AnalyticalPlatformTeamListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.state_bucket.s3_bucket_arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.analytical_platform_team_access_role.names)}"]
    }
  }
  statement {
    sid    = "AnalyticalPlatformTeamReadWriteBucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = ["${module.state_bucket.s3_bucket_arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.analytical_platform_team_access_role.names)}"]
    }
  }
  // Data Engineering Team
  statement {
    sid       = "DataEngineeringTeamListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.state_bucket.s3_bucket_arn]
    principals {
      type        = "AWS"
      identifiers = [module.data_engineering_state_access_iam_role.iam_role_arn]
    }
  }
  statement {
    sid    = "DataEngineeringTeamReadWriteBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${module.state_bucket.s3_bucket_arn}/aws/analytical-platform-data-engineering-production/*",
      "${module.state_bucket.s3_bucket_arn}/aws/analytical-platform-data-engineering-sandbox-a/*",
      "${module.state_bucket.s3_bucket_arn}/aws/analytical-platform-data-production/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [module.data_engineering_state_access_iam_role.iam_role_arn]
    }
  }
}

module "state_bucket" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.3.1"

  bucket = "global-tf-state-aqsvzyd5u9"

  attach_policy = true
  policy        = data.aws_iam_policy_document.state_bucket_policy.json
}

import {
  to = module.state_bucket.aws_s3_bucket.this[0]
  id = "global-tf-state-aqsvzyd5u9"
}

import {
  to = module.state_bucket.aws_s3_bucket_public_access_block.this[0]
  id = "global-tf-state-aqsvzyd5u9"
}
