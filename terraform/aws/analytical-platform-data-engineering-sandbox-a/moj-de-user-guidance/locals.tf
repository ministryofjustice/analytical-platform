locals {
  embedding_model_arn = "arn:${data.aws_partition.current.partition}:bedrock:${var.region}::foundation-model/${var.embedding_model_id}"

  s3_bucket_arn       = "arn:${data.aws_partition.current.partition}:s3:::${var.s3_bucket_name}"
  s3_bucket_objects   = "${local.s3_bucket_arn}/*"

  kb_role_name        = "${var.project_name}-bedrock-kb-role"
  kb_policy_name      = "${var.project_name}-bedrock-kb-policy"

  encryption_policy_name = "${var.project_name}-enc"
  network_policy_name    = "${var.project_name}-net"
  access_policy_name     = "${var.project_name}-data"
}