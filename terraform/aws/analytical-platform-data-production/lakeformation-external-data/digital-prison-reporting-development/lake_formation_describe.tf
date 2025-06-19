# resource "aws_lakeformation_permissions" "grant_describe_on_resource_link" {
#   provider    = aws.session
#   principal   = "arn:aws:iam::593291632749:role/alpha_user_andrewc-moj" # APDP role
#   permissions = ["DESCRIBE"]
#
#   database {
#     name = "dpr_ap_integration_test_tag_dev_dbt_resource_link" # The resource link DB name in APDP
#   }
# }
# resource "aws_lakeformation_permissions" "grant_describe_on_table_link" {
#   provider = aws.session
#   for_each = toset(["dev_model_1_notag", "dev_model_2_tag"])
#
#   principal   = "arn:aws:iam::593291632749:role/alpha_user_andrewc-moj"
#   permissions = ["DESCRIBE"]
#
#   table {
#     database_name = "dpr_ap_integration_test_tag_dev_dbt_resource_link"
#     name          = each.key
#   }
# }
