data "aws_iam_roles" "platform_engineer_admin" {
  provider = aws.platform_engineer_admin_source

  # AWS Identity Centre role names include a generated suffix; match by stable prefix.
  name_regex  = "^AWSReservedSSO_platform-engineer-admin_.*$"
  path_prefix = "/aws-reserved/sso.amazonaws.com/eu-west-2/"
}

module "analytical_platform_infrastructure_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.0"

  name            = "analytical-platform-infrastructure-access"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::509399598587:role/analytical-platform-github-actions"]
      }]
    }
    platformEngineerAssumeRole = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = [one(data.aws_iam_roles.platform_engineer_admin.arns)]
      }]
    }
  }

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}
