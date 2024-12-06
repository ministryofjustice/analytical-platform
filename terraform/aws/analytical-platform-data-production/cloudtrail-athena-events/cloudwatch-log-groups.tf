module "cloudtrail_athena_events_log_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.6.1"

  name = "cloudtrail-athena-events"
}
