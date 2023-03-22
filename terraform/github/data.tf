data "aws_caller_identity" "current" {
  provider = aws.session-info
}

data "aws_iam_session_context" "whoami" {
  provider = aws.session-info
  arn      = data.aws_caller_identity.current.arn
}

data "aws_caller_identity" "data" {
  provider = aws.data
}

data "aws_iam_session_context" "data" {
  provider = aws.data
  arn      = data.aws_caller_identity.data.arn
}
