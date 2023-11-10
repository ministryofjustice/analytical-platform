resource "aws_cloudwatch_log_group" "auth0" {
  #ts:skip=AWS.ACLG.LM.MEDIUM.0068 this is nonproduction code, will be addresses when productionised
  name = "/aws/events/auth0/alpha-analytics-moj"
}
