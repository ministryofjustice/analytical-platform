module "cloudtrail_athena_events_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.6.1"

  name = "cloudtrail-athena-events"
}
