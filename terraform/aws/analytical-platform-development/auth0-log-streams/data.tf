data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_cloudwatch_event_bus" "auth0" {
  name = "aws.partner/auth0.com/alpha-analytics-moj-c855a398-59a4-44d3-b042-7873e5a9ba75/auth0.logs"
}
