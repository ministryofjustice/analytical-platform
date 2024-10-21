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
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.analytical_platform_team_access_role.names)}"]
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
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.analytical_platform_team_access_role.names)}"]
    }
  }
  // Data Engineering: Data Engineering Production
  statement {
    sid       = "DataEngineeringProductionListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.state_bucket.s3_bucket_arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_engineering_production_data_eng.names)}"]
    }
  }
  statement {
    sid    = "DataEngineeringProductionReadWriteBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${module.state_bucket.s3_bucket_arn}/aws/analytical-platform-data-engineering-production/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_engineering_production_data_eng.names)}"]
    }
  }
  // Data Engineering: Data Engineering Sandbox A
  statement {
    sid       = "DataEngineeringSandboxAListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.state_bucket.s3_bucket_arn]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_engineering_sandbox_a_admin.names)}",
        "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_engineering_sandbox_a_data_eng.names)}"
      ]
    }
  }
  statement {
    sid    = "DataEngineeringSandboxAReadWriteBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${module.state_bucket.s3_bucket_arn}/aws/analytical-platform-data-engineering-sandbox-a/*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_engineering_sandbox_a_admin.names)}",
        "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_engineering_sandbox_a_data_eng.names)}"
      ]
    }
  }
  // Data Engineering: Data Production
  statement {
    sid       = "DEDataProductionListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.state_bucket.s3_bucket_arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_production_data_eng.names)}"]
    }
  }
  statement {
    sid    = "DEDataProductionReadWriteBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${module.state_bucket.s3_bucket_arn}/aws/analytical-platform-data-production/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_production_data_eng.names)}"]
    }
  }
}

module "state_bucket" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.1"

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
