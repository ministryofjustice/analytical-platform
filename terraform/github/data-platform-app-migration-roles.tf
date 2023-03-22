// Fetch Existing Roles
data "aws_iam_roles" "data_app_roles" {
  provider   = aws.data
  for_each   = local.migration_apps_map
  name_regex = format("alpha_app_%s", each.key)
}

data "aws_iam_role" "app_role_details" {
  provider = aws.data
  for_each = data.aws_iam_roles.data_app_roles
  name     = one(each.value.names)
}

# The policy is derived using the following naming convention:
# namespace: "data-platforms-app-<new repo name>-(prod|dev)
# serviceaccount: <namespace>

data "aws_iam_policy_document" "additional_statement" {
  for_each = data.aws_iam_role.app_role_details
  statement {
    sid    = "AllowCloudPlatformOIDCProvider"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.cloud_platform_eks_oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.cloud_platform_eks_oidc_provider_id}:sub"
      values = [
        "system:serviceaccount:data-platform-app-${each.key}-dev:data-platform-app-${each.key}-dev",
        "system:serviceaccount:data-platform-app-${each.key}-prod:data-platform-app-${each.key}-prod"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.cloud_platform_eks_oidc_provider_id}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

// Using source and override policy documents to avoid re-adding the same policy statement on every rerun

data "aws_iam_policy_document" "updated_trust" {
  for_each                  = data.aws_iam_role.app_role_details
  source_policy_documents   = [each.value.assume_role_policy]
  override_policy_documents = [data.aws_iam_policy_document.additional_statement[each.key].json]
}

// Creating policy so that it can be attached to the existing roles

# resource "aws_iam_role_policy" "updated_trust" {
#   for_each = data.aws_iam_role.app_role_details
#   provider = aws.data
#   name     = each.key
#   role     = each.value.name

#   policy = data.aws_iam_policy_document.updated_trust[each.key].json
# }

// Use local-exec to update trust policies as not doable with terraform

resource "null_resource" "update_iam_role_trust_policy" {
  for_each = data.aws_iam_role.app_role_details
  triggers = {
    trust_policy = data.aws_iam_policy_document.updated_trust[each.key].json
  }

  provisioner "local-exec" {
    command = <<EOF
    if grep -q "SSO" <<< $(aws sts get-caller-identity); then # Needed when running locally using aws-vault https://github.com/hashicorp/terraform-provider-aws/issues/8242#issuecomment-696828321
        unset AWS_SECURITY_TOKEN
    fi
    TEMP_CREDS=$(aws sts assume-role --role-arn ${data.aws_iam_session_context.data.issuer_arn} --role-session-name localexecupdatetrust)
    export AWS_ACCESS_KEY_ID=$(echo $TEMP_CREDS | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $TEMP_CREDS | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo $TEMP_CREDS | jq -r '.Credentials.SessionToken')
    aws sts get-caller-identity
    aws iam update-assume-role-policy --role-name ${each.value.name} --policy-document '${data.aws_iam_policy_document.updated_trust[each.key].json}'
  EOF
  }
}

