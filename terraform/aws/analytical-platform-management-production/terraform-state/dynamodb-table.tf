module "state_locking" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.2.0"

  name = "global-tf-state-aqsvzyd5u9-locks"
}

import {
  to = module.state_locking.aws_dynamodb_table.this[0]
  id = "global-tf-state-aqsvzyd5u9-locks"
}

data "aws_iam_policy_document" "state_locking_policy" {
  // GitHub Actions via GlobalGitHubActionAdmin
  statement {
    sid    = "GlobalGitHubActionAdmin"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [module.state_locking.dynamodb_table_arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"]
    }
  }
  // Analytical Platform Team
  statement {
    sid    = "AnalyticalPlatformTeam"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [module.state_locking.dynamodb_table_arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.analytical_platform_team_access_role.names)}"]
    }
  }
  // Data Engineering: Data Engineering Production
  statement {
    sid    = "DataEngineeringProduction"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [module.state_locking.dynamodb_table_arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_engineering_production_data_eng.names)}"]
    }
  }
  // Data Engineering: Data Engineering Sandbox A
  statement {
    sid    = "DataEngineeringSandboxA"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [module.state_locking.dynamodb_table_arn]
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
    sid    = "DataProduction"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [module.state_locking.dynamodb_table_arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_team_access_role_data_production_data_eng.names)}"]
    }
  }
}

resource "aws_dynamodb_resource_policy" "state_locking_policy" {
  resource_arn = module.state_locking.dynamodb_table_arn
  policy       = data.aws_iam_policy_document.state_locking_policy.json
}