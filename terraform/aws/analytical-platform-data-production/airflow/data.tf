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
data "aws_caller_identity" "target_account" {
  # tflint:ignore terraform_unused_declarations
}

# Management Production
data "aws_caller_identity" "analytical_platform_management_production" {
  # tflint:ignore terraform_unused_declarations

  provider = aws.analytical-platform-management-production
}
