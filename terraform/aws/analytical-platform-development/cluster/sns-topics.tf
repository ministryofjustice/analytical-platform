##################################################
# Control Panel Alerts
##################################################

resource "aws_sns_topic" "control_panel_alerts" {
  #ts:skip=AWS.AST.DP.MEDIUM.0037 skipping for now, will revisit

  name_prefix       = "control-panel-alerts"
  kms_master_key_id = "alias/aws/sns"
}

##################################################
# Compute Alerts
##################################################

resource "aws_sns_topic" "analytical_platform_compute_alerts" {
  #ts:skip=AWS.AST.DP.MEDIUM.0037 skipping for now, will revisit
  name_prefix       = "analytical-platform-compute-alerts"
  kms_master_key_id = "alias/aws/sns"
}

##################################################
# Networking Alerts
##################################################

resource "aws_sns_topic" "analytical_platform_networking_alerts" {
  #ts:skip=AWS.AST.DP.MEDIUM.0037 skipping for now, will revisit
  name_prefix       = "analytical-platform-networking-alerts"
  kms_master_key_id = "alias/aws/sns"
}

##################################################
# Storage Alerts
##################################################

resource "aws_sns_topic" "analytical_platform_storage_alerts" {
  #ts:skip=AWS.AST.DP.MEDIUM.0037 skipping for now, will revisit
  name_prefix       = "analytical-platform-storage-alerts"
  kms_master_key_id = "alias/aws/sns"
}
