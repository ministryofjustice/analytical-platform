#tfsec:ignore:AVD-AWS-0017
resource "aws_cloudwatch_log_group" "auth0" {
  #ts:skip=AWS.ACLG.LM.MEDIUM.0068 this is nonproduction code, will be addresses when productionised
  #checkov:skip=CKV_AWS_66 This code is being retired
  #checkov:skip=CKV_AWS_158         "      "
  #checkov:skip=CKV_AWS_338         "      "
  name = "/aws/events/auth0/alpha-analytics-moj"
}
