resource "aws_glue_catalog_database" "alpha_vcms_data" {
  name = "alpha-vcms-data"
}

resource "aws_glue_catalog_database" "alpha_vcms_data_underscore_name" {
  name = "alpha_vcms_data"
}
