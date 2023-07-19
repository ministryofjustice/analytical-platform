resource "aws_opensearch_domain" "openmetadata" {
  #checkov:skip=CKV_AWS_84:If productionised, will revisit this - Ensure Elasticsearch Domain Logging is enabled
  #checkov:skip=CKV_AWS_317:If productionised, will revisit this - Ensure Elasticsearch Domain Audit Logging is enabled
  #checkov:skip=CKV_AWS_247:If productionised, will revisit this - Ensure all data stored in the Elasticsearch is encrypted with a CMK

  domain_name    = "openmetadata"
  engine_version = "OpenSearch_1.3"

  vpc_options {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [module.opensearch_security_group.security_group_id]
  }

  cluster_config {
    dedicated_master_enabled = true
    dedicated_master_count   = 3
    dedicated_master_type    = "m6g.large.search"
    instance_count           = 6
    instance_type            = "r6g.large.search"
    zone_awareness_enabled   = true
    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "openmetadata"
      master_user_password = random_password.opensearch_master_password.result
    }
  }

  node_to_node_encryption {
    enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 100
  }
}

data "aws_iam_policy_document" "opensearch_domain" {
  #checkov:skip=CKV_AWS_283:Required as per AWS documentation

  statement {
    effect  = "Allow"
    actions = ["es:ESHttp*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["${aws_opensearch_domain.openmetadata.arn}/*"]
  }
}

resource "aws_opensearch_domain_policy" "openmetadata" {
  domain_name     = aws_opensearch_domain.openmetadata.domain_name
  access_policies = data.aws_iam_policy_document.opensearch_domain.json
}
