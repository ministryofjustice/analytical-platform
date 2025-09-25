# module "rds_export_kms_preprod" {

#   # Commit hash for v3.1.0
#   source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms?ref=fe1beca2118c0cb528526e022a53381535bb93cd"

#   aliases               = ["rds/rds-${local.name}"]
#   description           = "Used in the HMPPS probation domain to encode secrets and exported snapshots for RDS export"
#   enable_default_policy = true

#   key_statements = [
#     {
#       sid    = "AllowLambdaServiceAccess"
#       effect = "Allow"
#       actions = [
#         "kms:Encrypt*",
#         "kms:Decrypt*",
#         "kms:GenerateDataKey*",
#         "kms:Describe*"
#       ]
#       resources = ["*"]

#       principals = [
#         {
#           type        = "Service"
#           identifiers = ["lambda.amazonaws.com"]
#         }
#       ]
#     }
#   ]

#   deletion_window_in_days = 7

#   tags = var.tags
# }
