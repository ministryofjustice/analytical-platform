resource "awscc_bedrock_knowledge_base" "kb" {
  count = var.skip_kb_creation ? 0 : 1

  name     = local.kb_name
  role_arn = aws_iam_role.bedrock_kb_role.arn

  knowledge_base_configuration = {
    type = "VECTOR"
    vector_knowledge_base_configuration = {
      embedding_model_arn = local.embedding_model_arn
    }
  }

  storage_configuration = {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration = {
      collection_arn    = aws_opensearchserverless_collection.vector.arn
      vector_index_name = var.index_name
      field_mapping = {
        vector_field   = var.vector_field
        text_field     = var.text_field
        metadata_field = var.metadata_field
      }
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_opensearchserverless_collection.vector,
    aws_opensearchserverless_access_policy.data,
    null_resource.create_index
  ]
}

resource "awscc_bedrock_data_source" "s3" {
  count = var.skip_kb_creation ? 0 : 1
  
  knowledge_base_id = awscc_bedrock_knowledge_base.kb[0].id
  name              = local.data_source_name

  data_source_configuration = {
    type = "S3"
    s3_configuration = {
      bucket_arn = local.s3_bucket_arn
    }
  }
}