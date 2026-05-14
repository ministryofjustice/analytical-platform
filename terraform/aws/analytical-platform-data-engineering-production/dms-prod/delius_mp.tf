# Creating to test new mp endpoint
# To delete resources after testing connection

locals {
  database_credentials    = jsondecode(data.aws_secretsmanager_secret_version.database_credentials.secret_string)
  engine_name             = "oracle"
  secrets_manager_arn     = aws_secretsmanager_secret.delius_prod_secret.arn
  sid                     = "prdndas2"

  extra_connection_attributes = "addSupplementalLogging=N;additionalArchivedLogDestId=3;allowSelectNestedTables=True;archivedLogDestId=1;asm_server=delius-core-prod-db-1.delius-core.hmpps-production.modernisation-platform.service.justice.gov.uk/+ASM;asm_user=delius_analytics_platform;parallelASMReadThreads=8;readAheadBlocks=200000;useBfile=Y;useLogminerReader=N;"
}

data "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = local.secrets_manager_arn
}

resource "aws_dms_endpoint" "source_delius_mp" {
  #checkov:skip=CKV_AWS_296: Use AWS managed KMS key

  endpoint_id   = "delius-prod-mp-source"
  endpoint_type = "source"
  engine_name   = local.engine_name

  database_name = local.sid
  server_name   = "delius-core-prod-db-1.delius-core.hmpps-production.modernisation-platform.service.justice.gov.uk"
  username      = local.database_credentials["username"]
  password      = "${local.database_credentials["oracle_password"]},${local.database_credentials["asm_password"]}"
  port          = local.database_credentials["port"]

  extra_connection_attributes = local.extra_connection_attributes

  tags = merge(
    { Name = "delius-prod-mp-source" },
    var.tags
  )
}
