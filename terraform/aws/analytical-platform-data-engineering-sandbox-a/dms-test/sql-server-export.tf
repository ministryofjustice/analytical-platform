module "sql_server_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=sql-backup-restore"

  name                = "dmet-sql-server"
  kms_key_arn         = "arn:aws:kms:eu-west-1:684969100054:key/50db1101-acdf-421b-83ff-bffad889ac73"
  vpc_id              = module.vpc.vpc_id
  database_subnet_ids = module.vpc.private_subnets

  tags = local.tags
}
