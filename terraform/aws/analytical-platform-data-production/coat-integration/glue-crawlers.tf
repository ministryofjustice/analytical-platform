resource "aws_glue_crawler" "coat" {
  #checkov:skip=CKV_AWS_195:Glue Security Configuration is not required for this crawler

  name          = "${local.bucket_name}-glue-crawler"
  database_name = aws_glue_catalog_database.coat.name
  role          = module.glue_crawler_iam_role.iam_role_name

  s3_target {
    path = "s3://${module.coat_s3.s3_bucket_id}"
  }
}
