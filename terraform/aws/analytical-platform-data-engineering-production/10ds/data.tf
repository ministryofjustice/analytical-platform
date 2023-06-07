##################################################
# AWS
##################################################

# Calling session
data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

# Target account
# tflint-ignore: terraform_unused_declarations
data "aws_caller_identity" "target_account" {}

# Management Production
# tflint-ignore: terraform_unused_declarations
data "aws_caller_identity" "analytical_platform_management_production" {
  provider = aws.analytical-platform-management-production
}

data "aws_availability_zones" "available" {}
