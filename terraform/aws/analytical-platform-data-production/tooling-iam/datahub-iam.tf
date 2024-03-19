#trivy:ignore:aws-iam-no-policy-wildcards

locals {
  ingest_athena_nons3 = [
    "arn:aws:athena::${var.account_ids["analytical-platform-data-production"]}:datacatalog/*",
    "arn:aws:athena::${var.account_ids["analytical-platform-data-production"]}:workgroup/*",
    "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:tableVersion/*/*/*",
    "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:table/*/*",
    "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:catalog",
    "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:database/*"
  ]
  ingest_athena_s3 = concat(
    formatlist("arn:aws:s3:::%s/*", var.data_buckets),
    formatlist("arn:aws:s3:::%s", var.data_buckets)
  )
}

data "aws_iam_policy_document" "datahub_ingest_athena_datasets" {
  statement {
    sid    = "datahubIngestAthenaDatasets"
    effect = "Allow"
    actions = [
      "athena:GetTableMetadata",
      "athena:StartQueryExecution",
      "athena:GetQueryResults",
      "athena:GetDatabase",
      "athena:ListDataCatalogs",
      "athena:GetDataCatalog",
      "athena:ListQueryExecutions",
      "athena:GetWorkGroup",
      "athena:StopQueryExecution",
      "athena:GetQueryResultsStream",
      "athena:ListDatabases",
      "athena:GetQueryExecution",
      "athena:ListTableMetadata",
      "athena:BatchGetQueryExecution",
      "glue:GetTables",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:SearchTables",
      "glue:GetTableVersions",
      "glue:GetTableVersion",
      "glue:GetPartition",
      "glue:GetPartitions",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = concat(local.ingest_athena_nons3, local.ingest_athena_s3)
  }
}

resource "aws_iam_policy" "datahub_ingest_athena_datasets" {
  name   = "datahub_ingest_athena_datasets"
  policy = data.aws_iam_policy_document.datahub_ingest_athena_datasets.json
}

data "aws_iam_policy_document" "datahub_ingest_athena_query_results" {
  statement {
    sid    = "datahubIngestAthenaQueryResults"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListMultipartUploadParts"
    ]
    resources = concat(
      formatlist("arn:aws:s3:::%s/*", var.athena_query_result_buckets),
      formatlist("arn:aws:s3:::%s", var.athena_query_result_buckets)
    )
  }
}

resource "aws_iam_policy" "datahub_ingest_athena_query_results" {
  name   = "datahub_ingest_athena_query_results"
  policy = data.aws_iam_policy_document.datahub_ingest_athena_query_results.json
}


#trivy:ignore:avd-aws-0057:sensitive action 's3:*' on wildcarded resource
data "aws_iam_policy_document" "datahub_read_cadet_bucket" {
  statement {
    sid    = "datahubReadCaDeTBucket"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Describe*"
    ]
    resources = [
      "arn:aws:s3:::mojap-derived-tables/*",
      "arn:aws:s3:::mojap-derived-tables"
    ]
  }
}

resource "aws_iam_policy" "datahub_read_cadet_bucket" {
  name   = "datahub_read_CaDeT_bucket"
  policy = data.aws_iam_policy_document.datahub_read_cadet_bucket.json
}

#trivy:ignore:avd-aws-0057:sensitive action 'glue:GetDatabases' on wildcarded resource
data "aws_iam_policy_document" "datahub_ingest_glue_datasets" {
  statement {
    sid    = "datahubIngestGlueDatasets"
    effect = "Allow"
    actions = [
      "glue:GetDatabases",
      "glue:GetTables"
    ]
    resources = [
      "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:catalog",
      "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:database/*",
      "arn:aws:glue::${var.account_ids["analytical-platform-data-production"]}:table/*"
    ]
  }
}

resource "aws_iam_policy" "datahub_ingest_glue_datasets" {
  name   = "datahub_ingest_glue_datasets"
  policy = data.aws_iam_policy_document.datahub_ingest_glue_datasets.json
}


data "aws_iam_policy_document" "datahub_ingest_glue_jobs" {
  statement {
    sid    = "datahubIngestGlueJobs"
    effect = "Allow"
    actions = [
      "glue:GetDataflowGraph",
      "glue:GetJobs",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "datahub_ingest_glue_jobs" {
  name   = "datahub_ingest_glue_jobs"
  policy = data.aws_iam_policy_document.datahub_ingest_glue_jobs.json
}


resource "aws_iam_role" "datahub_ingestion_roles" {
  for_each = var.datahub_cp_irsa_arns
  name     = "datahub_ingestion_${each.key}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Action = ["sts:AssumeRole", "sts:TagSession"]
      Effect = "Allow"
      Principal = {
        AWS = each.value
      }
    }
  })
  managed_policy_arns = [
    aws_iam_policy.datahub_read_cadet_bucket.arn,
    aws_iam_policy.datahub_ingest_athena_datasets.arn,
    aws_iam_policy.datahub_ingest_athena_query_results.arn,
    aws_iam_policy.datahub_ingest_glue_datasets.arn,
    aws_iam_policy.datahub_ingest_glue_jobs.arn
  ]
}
