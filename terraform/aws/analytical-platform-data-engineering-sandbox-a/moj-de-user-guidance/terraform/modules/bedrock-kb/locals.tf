locals {
  name_prefix = "${var.project_name}-${var.environment}"

  collection_name  = local.name_prefix
  kb_name          = "${local.name_prefix}-kb"
  kb_role_name     = "${local.name_prefix}-kb-role"
  kb_policy_name   = "${local.name_prefix}-kb-policy"
  data_source_name = "${local.name_prefix}-s3"

  embedding_model_arn = "arn:${data.aws_partition.current.partition}:bedrock:${var.region}::foundation-model/${var.embedding_model_id}"
  #s3_bucket_arn       = "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket_name}"
  #s3_bucket_objects   = "${local.s3_bucket_arn}/*"

  s3_bucket_arn = var.create_s3_bucket ? aws_s3_bucket.knowledge_base[0].arn : data.aws_s3_bucket.existing[0].arn
  s3_bucket_id  = var.create_s3_bucket ? aws_s3_bucket.knowledge_base[0].id : data.aws_s3_bucket.existing[0].id

  caller_arn = data.aws_caller_identity.current.arn

  is_assumed_role = length(regexall("assumed-role", local.caller_arn)) > 0

  assumed_role_name = local.is_assumed_role ? regex("assumed-role/([^/]+)/", local.caller_arn)[0] : ""

  # Use IAM role lookup to get real ARN with path
  caller_role_arn = local.is_assumed_role ? data.aws_iam_role.caller[0].arn : local.caller_arn

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_role" "caller" {
  count = local.is_assumed_role ? 1 : 0
  name  = local.assumed_role_name
}