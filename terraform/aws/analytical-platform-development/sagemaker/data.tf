##################################################
# AWS
##################################################

data "aws_iam_policy" "lake_formation_data_access" {
  name = "lake-formation-data-access-additional"
}
