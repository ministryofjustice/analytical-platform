data "aws_caller_identity" "current" {}

locals {
  region              = "eu-west-1"
  kb_name             = "moj-de-user-guidance-kb"
  collection_name     = "moj-de-kb-vector"
  vector_index_name   = "bedrock-knowledge-base-default-index"
  embed_model_arn     = "arn:aws:bedrock:eu-west-1::foundation-model/amazon.titan-embed-text-v2:0"
}

# ----------------------------
# 1) IAM Role for Bedrock KB
# ----------------------------
resource "aws_iam_role" "bedrock_kb" {
  name = "bedrock-kb-${local.kb_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:bedrock:eu-west-1:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
        }
      }
    }]
  })

  tags = { Name = "bedrock-kb-${local.kb_name}" }
}

resource "aws_iam_role_policy" "bedrock_kb_s3" {
  name = "s3-access"
  role = aws_iam_role.bedrock_kb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        module.moj_de_user_guidance.s3_bucket_arn,
        "${module.moj_de_user_guidance.s3_bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_model" {
  name = "bedrock-model-access"
  role = aws_iam_role.bedrock_kb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = local.embed_model_arn
    }]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_aoss" {
  name = "aoss-api-access"
  role = aws_iam_role.bedrock_kb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["aoss:APIAccessAll"]
      Resource = "*"
    }]
  })
}

# -----------------------------------------
# 2) OpenSearch Serverless (Vector store)
# -----------------------------------------
resource "aws_opensearchserverless_security_policy" "kb_encryption" {
  name = "${local.collection_name}-encryption"
  type = "encryption"

  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${local.collection_name}"]
    }]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "kb_network" {
  name = "${local.collection_name}-network"
  type = "network"

  policy = jsonencode([{
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${local.collection_name}"]
    }]
    AllowFromPublic = true
  }])
}

resource "aws_opensearchserverless_collection" "kb_vector" {
  name = local.collection_name
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.kb_encryption,
    aws_opensearchserverless_security_policy.kb_network
  ]

  tags = { Name = local.collection_name }
}

resource "aws_opensearchserverless_access_policy" "kb_data" {
  name = "${local.collection_name}-data"
  type = "data"

  policy = jsonencode([{
    Description = "Allow Bedrock KB to manage vectors"
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${local.collection_name}"]
        Permission   = ["aoss:CreateCollectionItems", "aoss:UpdateCollectionItems", "aoss:DescribeCollectionItems"]
      },
      {
        ResourceType = "index"
        Resource     = ["index/${local.collection_name}/*"]
        Permission   = ["aoss:CreateIndex", "aoss:DescribeIndex", "aoss:ReadDocument", "aoss:WriteDocument", "aoss:UpdateIndex", "aoss:DeleteIndex"]
      }
    ]
    Principal = [
      aws_iam_role.bedrock_kb.arn,
      coalesce(var.terraform_runner_principal_arn, data.aws_caller_identity.current.arn)
    ]
  }])

  depends_on = [aws_opensearchserverless_collection.kb_vector]
}

# Wait for IAM policy propagation
resource "time_sleep" "wait_for_aoss_policy" {
  depends_on = [aws_opensearchserverless_access_policy.kb_data]

  create_duration = "30s"
}

resource "null_resource" "create_opensearch_index" {
  triggers = {
    endpoint     = aws_opensearchserverless_collection.kb_vector.collection_endpoint
    index_name   = local.vector_index_name
    mapping_hash = filesha256("${path.module}/opensearch-index.json")
  }

  provisioner "local-exec" {
    command = "python3 ${path.module}/scripts/create-opensearch-index.py ${aws_opensearchserverless_collection.kb_vector.collection_endpoint} ${local.vector_index_name} ${path.module}/opensearch-index.json"
  }

  depends_on = [time_sleep.wait_for_aoss_policy]
}

# -----------------------------------------
# 3) Bedrock Knowledge Base
# -----------------------------------------
resource "aws_bedrockagent_knowledge_base" "moj_de_guidance" {
  name     = local.kb_name
  role_arn = aws_iam_role.bedrock_kb.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = local.embed_model_arn
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.kb_vector.arn
      vector_index_name =local.vector_index_name

      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }

  depends_on = [
    time_sleep.wait_for_aoss_policy,
    null_resource.create_opensearch_index,
    aws_iam_role_policy.bedrock_kb_s3,
    aws_iam_role_policy.bedrock_kb_model,
    aws_iam_role_policy.bedrock_kb_aoss
  ]

  tags = { Name = local.kb_name }
}

# -----------------------------------------
# 3) Data source (S3 -> Knowledge Base)
# -----------------------------------------
resource "aws_bedrockagent_data_source" "moj_de_guidance_s3" {
  name              = "moj-de-guidance-s3-source"
  knowledge_base_id = aws_bedrockagent_knowledge_base.moj_de_guidance.id

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = module.moj_de_user_guidance.s3_bucket_arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}

output "knowledge_base_id" {
  value = aws_bedrockagent_knowledge_base.moj_de_guidance.id
}

output "data_source_id" {
  value = aws_bedrockagent_data_source.moj_de_guidance_s3.data_source_id
}