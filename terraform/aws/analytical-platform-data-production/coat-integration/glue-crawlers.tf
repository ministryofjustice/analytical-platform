resource "aws_glue_crawler" "coat" {
  name          = "${local.bucket_name}-glue-crawler"
  database_name = aws_glue_catalog_database.coat.name
  role          = module.glue_crawler_iam_role.iam_role_name

  s3_target {
    path = "s3://${module.coat_s3.s3_bucket_id}"
  }
}
