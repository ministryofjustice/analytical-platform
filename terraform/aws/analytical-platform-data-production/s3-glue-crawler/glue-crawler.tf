resource "aws_glue_crawler" "example" {
  database_name = aws_glue_catalog_database.alpha-vcms-data-glue-catalog.name
  name          = "vcms-data-crawler"
  role          = aws_iam_role.AWSGlueServiceRole_vcms_crawler.arn

  s3_target {
    path = "s3://alpha-vcms-data/vcms-data-3/vcms/"
  }
}