resource "aws_glue_crawler" "example" {
  database_name = aws_glue_catalog_database.alpha_vcms_data_glue_catalog.name
  name          = "vcms-data-crawler"
  role          = aws_iam_role.AWSGlueServiceRole_vcms_crawler.arn

  s3_target {
    path = "s3://alpha-vcms-data/vcms-data-3/vcms/"
  }
}