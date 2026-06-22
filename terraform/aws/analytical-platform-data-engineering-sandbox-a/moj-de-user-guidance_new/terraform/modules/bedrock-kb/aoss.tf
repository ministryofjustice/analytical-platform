resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${local.name_prefix}-enc"
  type = "encryption"

  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${local.collection_name}"]
    }]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "${local.name_prefix}-net"
  type = "network"

  policy = jsonencode([{
    Rules = [
      { ResourceType = "collection", Resource = ["collection/${local.collection_name}"] },
      { ResourceType = "dashboard", Resource = ["collection/${local.collection_name}"] }
    ]
    AllowFromPublic = true
  }])
}

resource "aws_opensearchserverless_collection" "vector" {
  name = local.collection_name
  type = "VECTORSEARCH"
  tags = local.common_tags

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network
  ]
}

resource "aws_opensearchserverless_access_policy" "data" {
  name = "${local.name_prefix}-data"
  type = "data"

  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${local.collection_name}"]
        Permission   = ["aoss:*"]
      },
      {
        ResourceType = "index"
        Resource     = ["index/${local.collection_name}/*"]
        Permission   = ["aoss:*"]
      }
    ]
    Principal = distinct(compact([
      aws_iam_role.bedrock_kb_role.arn,
      local.caller_role_arn,
      data.aws_caller_identity.current.arn,
      var.lambda_role_arn
    ]))
  }])

  depends_on = [aws_opensearchserverless_collection.vector]
}