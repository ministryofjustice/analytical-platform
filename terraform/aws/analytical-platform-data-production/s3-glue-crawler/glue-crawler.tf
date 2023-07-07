resource "aws_glue_crawler" "alpha_vmcs_data" {
  database_name = aws_glue_catalog_database.alpha_vcms_data.name
  name          = "alpha-vcms-data"
  role          = aws_iam_role.alpha_vcms_data_crawler.arn

  s3_target {
    path = "s3://alpha-vcms-data/vcms-data-3/vcms/"
  }
}
