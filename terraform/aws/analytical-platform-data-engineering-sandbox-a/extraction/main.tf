module "dms" {
  source = "../../modules/de-dms"

  environment                = "sandbox"
  db                         = "delius"
  source_secrets_manager_arn = "managed_pipelines/sandbox/oracle19"
  dms_source_server_name     = "oracle19.cn2clhldf81y.eu-west-1.rds.amazonaws.com"
  dms_source_database_name   = "ORACLE19"
}
