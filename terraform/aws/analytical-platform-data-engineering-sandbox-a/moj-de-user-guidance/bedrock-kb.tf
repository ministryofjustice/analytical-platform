resource "awscc_bedrock_knowledge_base" "kb" {
  name        = var.kb_name
  description = var.kb_description
  role_arn    = aws_iam_role.bedrock_kb_role.arn

  knowledge_base_configuration = {
    type = "VECTOR"
    vector_knowledge_base_configuration = {
      embedding_model_arn = local.embedding_model_arn
    }
  }

  storage_configuration = {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration = {
      collection_arn     = aws_opensearchserverless_collection.vector.arn
      vector_index_name  = var.index_name
      field_mapping = {
        vector_field   = var.vector_field
        text_field     = var.text_field
        metadata_field = var.metadata_field
      }
    }
  }

  depends_on = [
    null_resource.create_aoss_index,
    aws_iam_role_policy_attachment.bedrock_kb_policy_attach
  ]
}

resource "awscc_bedrock_data_source" "s3" {
  knowledge_base_id = awscc_bedrock_knowledge_base.kb.knowledge_base_id
  name              = var.data_source_name
  description       = "S3 data source for ${var.project_name}"

  data_source_configuration = {
    type = "S3"
    s3_configuration = {
      bucket_arn         = local.s3_bucket_arn
      inclusion_prefixes = var.s3_inclusion_prefixes
    }
  }

  data_deletion_policy = "DELETE"

  depends_on = [awscc_bedrock_knowledge_base.kb]
}