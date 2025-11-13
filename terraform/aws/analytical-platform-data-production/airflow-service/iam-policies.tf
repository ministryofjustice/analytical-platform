data "aws_iam_policy_document" "athena_read" {
  #checkov:skip=CKV_AWS_111:This code is ported from IAM Builder
  #checkov:skip=CKV_AWS_356:This code is ported from IAM Builder

  statement {
    sid    = "AthenaReadOnlyS3BucketActions"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }
  statement {
    sid     = "AthenaReadOnlyS3ListBuckets"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::alpha-athena-query-dump",
      "arn:aws:s3:::moj-analytics-lookup-tables",
      "arn:aws:s3:::mojap-athena-query-dump"
    ]
  }
  statement {
    sid       = "AthenaReadOnlyS3GetObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::moj-analytics-lookup-tables/*"]
  }
  statement {
    sid    = "AthenaReadOnlyS3GetPutObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::aws-athena-query-results-*"]
  }
  statement {
    sid    = "AthenaReadOnlyS3DeleteGetPutObjects"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::alpha-athena-query-dump/$${aws:userid}/*",
      "arn:aws:s3:::mojap-athena-query-dump/$${aws:userid}/*"
    ]
  }
  statement {
    sid    = "AthenaReadOnlyAthenaGlueRead"
    effect = "Allow"
    actions = [
      "athena:BatchGetNamedQuery",
      "athena:BatchGetQueryExecution",
      "athena:CancelQueryExecution",
      "athena:GetCatalogs",
      "athena:GetExecutionEngine",
      "athena:GetExecutionEngines",
      "athena:GetNamedQuery",
      "athena:GetNamespace",
      "athena:GetNamespaces",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryResultsStream",
      "athena:GetTable",
      "athena:GetTableMetadata",
      "athena:GetTables",
      "athena:GetWorkGroup",
      "athena:ListNamedQueries",
      "athena:ListQueryExecutions",
      "athena:ListWorkGroups",
      "athena:RunQuery",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "glue:BatchGetPartition",
      "glue:GetCatalogImportStatus",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:GetTableVersions",
      "glue:GetTables",
      "glue:GetUserDefinedFunction",
      "glue:GetUserDefinedFunctions"
    ]
    resources = ["*"]
  }
}

module "athena_read_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.1.0"

  path        = "/airflow-service/"
  name        = "athena-read"
  policy      = data.aws_iam_policy_document.athena_read.json
  description = "IAM Policy"
}

data "aws_iam_policy_document" "athena_write" {
  #checkov:skip=CKV_AWS_111:This code is ported from IAM Builder
  #checkov:skip=CKV_AWS_356:This code is ported from IAM Builder

  statement {
    sid    = "AthenaWrite"
    effect = "Allow"
    actions = [
      "athena:DeleteNamedQuery",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:BatchDeleteTable",
      "glue:CreateDatabase",
      "glue:CreatePartition",
      "glue:CreateTable",
      "glue:CreateUserDefinedFunction",
      "glue:DeleteDatabase",
      "glue:DeletePartition",
      "glue:DeleteTable",
      "glue:DeleteUserDefinedFunction",
      "glue:UpdateDatabase",
      "glue:UpdatePartition",
      "glue:UpdateTable",
      "glue:UpdateUserDefinedFunction"
    ]
    resources = ["*"]
  }
}

module "athena_write_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.1.0"

  path        = "/airflow-service/"
  name        = "athena-write"
  policy      = data.aws_iam_policy_document.athena_write.json
  description = "IAM Policy"
}

data "aws_iam_policy_document" "bedrock" {
  statement {
    sid    = "Bedrock"
    effect = "Allow"
    actions = [
      "bedrock:CreateModelCustomizationJob",
      "bedrock:DeleteCustomModel",
      "bedrock:GetCustomModel",
      "bedrock:GetFoundationModel",
      "bedrock:GetFoundationModelAvailability",
      "bedrock:GetModelCustomizationJob",
      "bedrock:GetModelInvocationLoggingConfiguration",
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:ListCustomModels",
      "bedrock:ListFoundationModels",
      "bedrock:ListModelCustomizationJobs",
      "bedrock:ListProvisionedModelThroughputs",
      "bedrock:ListTagsForResource",
      "bedrock:PutModelInvocationLoggingConfiguration",
      "bedrock:StopModelCustomizationJob",
      "bedrock:TagResource",
      "bedrock:UntagResource"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values = [
        "eu-central-1", # Europe (Frankfurt)
        "eu-north-1",   # Europe (Stockholm)
        "eu-south-1",   # Europe (Milan)
        "eu-south-2",   # Europe (Spain)
        "eu-west-1",    # Europe (Ireland)
        "eu-west-2",    # Europe (London)
        "eu-west-3",    # Europe (Paris)
        "us-east-1",    # US East (N. Virginia)
      ]
    }
  }
}

module "bedrock_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.1.0"

  path        = "/airflow-service/"
  name        = "bedrock"
  policy      = data.aws_iam_policy_document.bedrock.json
  description = "IAM Policy"
}

data "aws_iam_policy_document" "glue" {
  #checkov:skip=CKV_AWS_111:This code is ported from IAM Builder
  #checkov:skip=CKV_AWS_356:This code is ported from IAM Builder

  statement {
    sid    = "GlueActions"
    effect = "Allow"
    actions = [
      "glue:BatchGetJobs",
      "glue:BatchStopJobRun",
      "glue:CreateJob",
      "glue:DeleteJob",
      "glue:GetJob",
      "glue:GetJobBookmark",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:GetJobs",
      "glue:ListJobs",
      "glue:StartJobRun",
      "glue:UpdateJob"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "GlueLogs"
    effect = "Allow"
    actions = [
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:GetLogEvents",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "GlueMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:ListDashboards",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "GlueS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::aws-glue-*/*",
      "arn:aws:s3:::*/*aws-glue-*/*",
      "arn:aws:s3:::aws-glue-*"
    ]
  }
}

module "glue_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.1.0"

  path        = "/airflow-service/"
  name        = "glue"
  policy      = data.aws_iam_policy_document.glue.json
  description = "IAM Policy"
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid     = "DefaultKMS"
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    resources = [
      module.secrets_manager_kms.key_arn,
      module.secrets_manager_eu_west_1_replica_kms.key_arn
    ]
  }
}

module "kms_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.1.0"

  path        = "/airflow-service/"
  name        = "kms"
  policy      = data.aws_iam_policy_document.kms.json
  description = "IAM Policy"
}

data "aws_iam_policy_document" "create_a_derived_table" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:DeleteObject*",
      "s3:PutObject*"
    ]
    resources = [
      "arn:aws:s3:::mojap-derived-tables/*",
      "arn:aws:s3:::mojap-derived-tables",
      "arn:aws:s3:::dbt-query-dump/*",
      "arn:aws:s3:::dbt-query-dump",
      "arn:aws:s3:::mojap-manage-offences/ho-offence-codes/*",
      "arn:aws:s3:::mojap-manage-offences",
      "arn:aws:s3:::mojap-hub-exports/probation_referrals_dump/*",
      "arn:aws:s3:::mojap-hub-exports",
      "arn:aws:s3:::alpha-app-opg-lpa-dashboard",
      "arn:aws:s3:::alpha-app-opg-lpa-dashboard/dev/models/domain_name=opg/*",
      "arn:aws:s3:::alpha-app-opg-lpa-dashboard/prod/models/domain_name=opg/*",
      "arn:aws:s3:::alpha-bold-data-shares",
      "arn:aws:s3:::alpha-bold-data-shares/reducing-reoffending/*"
    ]
  }
  statement {
    sid    = "DataAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetObject*",
      "s3:GetBucket*"
    ]
    resources = [
      "arn:aws:s3:::*",
      "arn:aws:s3:::*/*"
    ]
  }
  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "athena:List*",
      "athena:Get*",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-production"]}:datacatalog/*",
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-production"]}:workgroup/*"
    ]
  }
  statement {
    sid    = "GlueAccess"
    effect = "Allow"
    actions = [
      "glue:Get*",
      "glue:DeleteTable",
      "glue:DeleteTableVersion",
      "glue:DeleteSchema",
      "glue:DeletePartition",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:UpdateSchema",
      "glue:UpdatePartition",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:CreateSchema",
      "glue:CreatePartition",
      "glue:CreatePartitionIndex",
      "glue:BatchCreatePartition",
      "glue:CreateDatabase"
    ]
    resources = [
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:schema/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:database/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:table/*/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-production"]}:catalog"
    ]
  }
}

module "cadet_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.1.0"

  path        = "/airflow-service/"
  name        = "cadet"
  policy      = data.aws_iam_policy_document.create_a_derived_table.json
  description = "IAM Policy"
}
