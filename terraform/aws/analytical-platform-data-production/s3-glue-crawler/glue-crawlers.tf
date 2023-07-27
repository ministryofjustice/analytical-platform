resource "aws_glue_crawler" "alpha_vmcs_data" {
  # checkov:skip=CKV_AWS_195:security configuration disabled
  # as crawler not writing encrypted data, only crawling
  # for schema and metadata
  name          = "alpha-vcms-data"
  database_name = aws_glue_catalog_database.alpha_vcms_data.name
  role          = aws_iam_role.alpha_vcms_data_crawler.arn

  s3_target {
    path = "s3://alpha-vcms-data/vcms-data-3/vcms/"
  }
}

resource "aws_glue_crawler" "alpha_vmcs_data_2" {
  # checkov:skip=CKV_AWS_195:security configuration disabled
  # as crawler not writing encrypted data, only crawling
  # for schema and metadata
  name          = "alpha-vcms-data_2"
  database_name = aws_glue_catalog_database.alpha_vcms_data_2.name
  role          = aws_iam_role.alpha_vcms_data_crawler.arn

  configuration = jsonencode(
    {
      CrawlerOutput = {
        Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      }
      Version = 1
    }
  )

  s3_target {
    path = "s3://alpha-vcms-data/vcms-data-3/vcms/"
  }
}
