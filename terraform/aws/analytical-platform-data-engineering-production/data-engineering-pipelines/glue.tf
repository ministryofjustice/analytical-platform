# required for the hmpps_probation_data_tables cadet project
# the schema in the profiles.yml becomes the default database
# for the connection so if it doesn't exist schema changes
# error
resource "aws_glue_catalog_database" "cadet_probation_schema" {
  name = "probation"
  description = "Used in profiles.yaml for CaDeT hmpps_probation_data_tables project. Do not delete."
}
