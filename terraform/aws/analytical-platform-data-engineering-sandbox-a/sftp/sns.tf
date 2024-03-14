# module "quarantine_topic" {
#   source  = "terraform-aws-modules/sns/aws"
#   version = "6.0.1"

#   name              = "ingestion-notifications-quarantine"
#   display_name      = "ingestion-notifications-quarantine"
#   signature_version = 2

#   kms_master_key_id = module.sns_kms.key_id

#   topic_policy_statements = {
#     AllowQuarantineS3 = {
#       actions = ["sns:Publish"]
#       principals = [{
#         type        = "Service"
#         identifiers = ["s3.amazonaws.com"]
#       }]
#       conditions = [
#         {
#           test     = "ArnEquals"
#           variable = "aws:SourceArn"
#           values   = [module.quarantine_bucket.s3_bucket_arn]
#         },
#         {
#           test     = "StringEquals"
#           variable = "aws:SourceAccount"
#           values   = [data.aws_caller_identity.current.account_id]
#         }
#       ]
#     }
#   }

#   subscriptions = {
#     lambda = {
#       protocol = "lambda"
#       endpoint = module.notify_lambda.lambda_function_arn
#     }
#   }
# }

# module "transfer_topic" {
#   source  = "terraform-aws-modules/sns/aws"
#   version = "6.0.1"

#   name              = "ingestion-notifications-transfer"
#   display_name      = "ingestion-notifications-transfer"
#   signature_version = 2

#   kms_master_key_id = module.sns_kms.key_id

#   subscriptions = {
#     lambda = {
#       protocol = "lambda"
#       endpoint = module.notify_lambda.lambda_function_arn
#     }
#   }
# }
