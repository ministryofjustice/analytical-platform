resource "aws_glue_crawler" "vmcs_data_crawler" {
  database_name = aws_glue_catalog_database.alpha_vcms_data_glue_catalog.name
  name          = "vcms-data-crawler"
  role          = aws_iam_role.glue_vcms_crawler_role.arn

  s3_target {
    path = "s3://alpha-vcms-data/vcms-data-3/vcms/"
  }
}
