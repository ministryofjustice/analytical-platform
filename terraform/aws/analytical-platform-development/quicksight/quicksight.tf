# # WOW WHAT'S QUICKSIGHT DOING HERE?!
# # This will be moved into analytical-platform-compute
# # I can't plan in there effectively at the moment as there is ongoing work :shrug:

# # Out of Scope:
# # - QuickSight Dashboards
# # - QuickSight DataSets

# # In Scope:
# # - QuickSight Account Subscription
# # - QuickSight DataSources
# #   - S3 Data Source
# #   - Athena Data Source
# #   - Glue Data Source

resource "aws_quicksight_account_subscription" "subscription" {
  account_name          = "analytical-platform-development" // CHANGE THIS IN MOD PLATFORM
  authentication_method = "IAM_IDENTITY_CENTER"
  edition               = "ENTERPRISE"
  admin_group           = ["analytical-platform"]  // CHANGE THIS IN MOD PLATFORM
  author_group          = ["analytical-platform"]  // CHANGE THIS IN MOD PLATFORM
  notification_email    = local.notification_email // CHANGE THIS IN MOD PLATFORM
}

# resource "aws_iam_role" "quicksight" {
#   name = "quicksight-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "quicksight.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_quicksight_data_source" "s3" {
#   data_source_id = "s3"
#   name           = "S3 QuickSight Data Source"

#   parameters {
#     s3 {
#       manifest_file_location {
#         bucket = "bucket-name"
#         key    = "path/to/manifest.json"
#       }
#     }
#   }

#   type = "S3"
# }

# resource "aws_quicksight_data_source" "athena" {
#   data_source_id = "athena"
#   name           = "Athena QuickSight Data Source"

#   parameters {
#     athena {
#       work_group = "primary"
#     }
#   }

#   type = "ATHENA"
# }

# NOT NEEDED
# resource "aws_quicksight_user" "admin" {
#   session_name  = "an-author"
#   email         = "author@example.com"
#   identity_type = "IAM"
#   iam_arn       = "arn:aws:iam::123456789012:user/Example"
#   user_role     = "AUTHOR"
# }


# # resource "aws_quicksight_data_source" "glue" {
# #   data_source_id = "glue"
# #   name           = "Glue QuickSight Data Source"

# #   parameters {
# #   }
# # }
